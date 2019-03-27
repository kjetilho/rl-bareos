#!/usr/bin/env python
# -*- coding: utf-8 -*-
# BAREOS - Backup Archiving REcovery Open Sourced
#
# Copyright (C) 2014-2017 Bareos GmbH & Co. KG
#
# This program is Free Software; you can redistribute it and/or
# modify it under the terms of version three of the GNU Affero General Public
# License as published by the Free Software Foundation, which is
# listed in the file LICENSE.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.
#
# Author: Trygve Vea <trygve.vea@redpill-linpro.com>
# based on code by Maik Aussendorf
#
# Bareos python plugin to backup S3 buckets

import sys
import time
from S3.ExitCodes import *
from S3.Exceptions import *
from S3 import PkgInfo
from S3.S3 import S3
from S3.Config import Config
from S3.SortedDict import SortedDict
from S3.FileDict import FileDict
from S3.S3Uri import S3Uri
from S3 import Utils
from S3 import Crypto
from S3.Utils import *
from S3.Progress import Progress
from S3.CloudFront import Cmd as CfCmd
from S3.CloudFront import CloudFront
from S3.FileLists import *
from S3.MultiPart import MultiPartUpload
from S3.ConnMan import ConnMan

import re
import bareosfd
from bareos_fd_consts import bJobMessageType, bFileType, bRCs, bIOPS
import os
import BareosFdPluginBaseclass


class BareosFdPluginS3(BareosFdPluginBaseclass.BareosFdPluginBaseclass):  # noqa

    def parse_plugin_definition(self, context, plugindef):
        '''
        Parses the plugin argmuents and reads files from file given by
        argument 'config'
        '''
        super(BareosFdPluginS3, self).parse_plugin_definition(
            context, plugindef)
        if ('config' not in self.options):
            bareosfd.DebugMessage(context, 100,
                                  "Option \'config\' not defined.\n")
            return bRCs['bRC_Error']
        if ('bucket' not in self.options):
            bareosfd.DebugMessage(context, 100,
                                  "Option \'bucket\' not defined.\n")
            return bRCs['bRC_Error']
        bareosfd.DebugMessage(context, 100,
                              "Using %s to look up plugin config\n"
                              % (self.options['config']))
        if os.path.exists(self.options['config']):
            try:
                cfg = Config(self.options['config'])
                #config_file = open(self.options['config'], 'rb')
            except:
                bareosfd.DebugMessage(context, 100,
                                      "Could not open file %s\n"
                                      % (self.options['config']))
                return bRCs['bRC_Error']
        else:
            bareosfd.DebugMessage(context, 100,
                                  "File %s does not exist\n"
                                  % (self.options['config']))
            return bRCs['bRC_Error']

        # `prefix` is the common substring for all object names.  Can be
        # a partial filename, not necessarily a folder.
        if ('prefix' not in self.options):
            self.options['prefix'] = None

        # Folders listed in `prefix` are filtered against `pattern`, and only
        # these folders are recursed into.
        if ('pattern' in self.options):
            self.pattern = re.compile(self.options['pattern'])
        else:
            self.pattern = None

        # Every (remaining) object name is filtered against `object_pattern`.
        if ('object_pattern' in self.options):
            self.object_pattern = re.compile(self.options['object_pattern'])
        else:
            self.object_pattern = None

        self.files_to_backup = []
        self.s3 = S3(cfg)
        self.current_prefix = self.options['prefix']
        self.prefix_list = [ self.options['prefix'] ]
        self.file_iterator = {}
        self.file_iterator['uri_params'] = None

        if self.pattern:
            self.make_prefix_list()

        self.iterate_files()

        return bRCs['bRC_OK']

    def make_prefix_list(self):
        topfiles = self.s3.bucket_list(self.options['bucket'], prefix=self.current_prefix, recursive=False)
        self.prefix_list = []
        for item in topfiles['common_prefixes']:
            pf = deunicodise(item['Prefix'])
            if self.pattern.match(pf):
                self.prefix_list.append(pf)

    def test_file_list(self):
        for item in self.file_iterator['list']:
            if self.object_pattern:
                if not self.object_pattern.match(deunicodise(item['Key'])):
                    continue
            if not deunicodise(item['Key'])[-1] == '/':
                self.files_to_backup.append({ 'size': int(item['Size']),
                                              'timestamp': int(dateRFC822toUnix(item['LastModified'])),
                                              'name': '/situla/' + self.options['bucket'] + '/' + deunicodise(item['Key']) })

    def iterate_files(self):
        if self.file_iterator['uri_params']:
            self.file_iterator = self.s3.bucket_list_iterate(self.options['bucket'], prefix=self.current_prefix, recursive=True, uri_params=self.file_iterator['uri_params'])
            self.test_file_list()
            if not self.files_to_backup:
                self.iterate_files()
            return

        if self.prefix_list:
            self.current_prefix = self.prefix_list.pop(0)
            self.file_iterator = self.s3.bucket_list_iterate(self.options['bucket'], prefix=self.current_prefix, recursive=True)
            self.test_file_list()
            if not self.files_to_backup:
                self.iterate_files()

    def start_backup_file(self, context, savepkt):
        '''
        Defines the file to backup and creates the savepkt. In this example
        only files (no directories) are allowed
        '''
        bareosfd.DebugMessage(context, 100, "start_backup called\n")
        if not self.files_to_backup:
            # add a synthetic entry for top-level to avoid "no fname in bareosCheckChanges packet."
            self.files_to_backup.append({ 'size': 0,
                                          'timestamp': int(time.time()),
                                          'name': '/situla/' + self.options['bucket'] + '/'})
            bareosfd.DebugMessage(context, 100, "No files to backup\n")

        file_to_backup = self.files_to_backup.pop(0)
        bareosfd.DebugMessage(context, 100, 'file: ' + file_to_backup['name'] + "\n")

        statp = bareosfd.StatPacket()
        statp.mtime = file_to_backup['timestamp']
        statp.ctime = file_to_backup['timestamp']
        statp.size  = file_to_backup['size']
        #savepkt.save_time = int(time.time())
        savepkt.statp = statp
        savepkt.fname = str(file_to_backup['name'])
        savepkt.type = bFileType['FT_REG']

        #bareosfd.JobMessage(context, bJobMessageType['M_INFO'],
        #                    "Starting backup of %s\n"
        #                    % (file_to_backup['name']))
        return bRCs['bRC_OK']

    def end_backup_file(self, context):
        '''
        Here we return 'bRC_More' as long as our list files_to_backup is not
        empty and bRC_OK when we are done
        '''
        bareosfd.DebugMessage(
            context, 100,
            "end_backup_file() entry point in Python called\n")
        if not self.files_to_backup:
            self.iterate_files()

        if self.files_to_backup:
            return bRCs['bRC_More']
        else:
            return bRCs['bRC_OK']

    def try_open(self, s3bucket, s3object):
        request = self.s3.create_request('OBJECT_GET', bucket = s3bucket, object = s3object)
        self.req = self.s3.recv_file_streamed(request)

    def plugin_io(self, context, IOP):
        bareosfd.DebugMessage(
            context, 100, "plugin_io called with function %s\n" % (IOP.func))
        bareosfd.DebugMessage(
            context, 100, "FNAME is set to %s\n" % (self.FNAME))

        if IOP.func == bIOPS['IO_OPEN']:
            self.FNAME = IOP.fname
            self.retry = 0
            sp = str(self.FNAME).split('/',3)
            s3bucket = sp[2]
            s3object = sp[3]
            if s3object == '':
                # This is the synthetic entry when there are no files in bucket.  Do nothing and be happy.
                return bRCs['bRC_OK']
            try:
                if IOP.flags & (os.O_CREAT | os.O_WRONLY):
                    bareosfd.DebugMessage(context, 100, "plugin does not support restore yet.\n")
                    IOP.status = -1
                    return bRCs['bRC_Error']
                else:
                    bareosfd.DebugMessage(context, 100, "Open file %s for reading with %s\n" % (self.FNAME, IOP))
                    self.try_open(s3bucket = s3bucket, s3object = s3object)

            except S3Error, e:
                if e.status == 404:
                    IOP.io_errno = 2
                    bareosfd.JobMessage(context, bJobMessageType['M_INFO'], "Attempt to open %s failed (404)\n" % (s3object))
                else:
                    if self.retry == 0:
                        retry = 1
                        bareosfd.JobMessage(context, bJobMessageType['M_INFO'], "Attempt to open %s failed (503), retrying once in 10 seconds\n" % (s3object))
                        time.sleep(10)
                        self.try_open(s3bucket = s3bucket, s3object = s3object)
                        return bRCs['bRC_OK']
                IOP.status = -1
                return bRCs['bRC_Error']

            except S3DownloadError, e:
                if self.retry == 0:
                    retry = 1
                    bareosfd.JobMessage(context, bJobMessageType['M_INFO'], "Attempt to open %s failed (HTTP Conn. err.), retrying once in 10 seconds\n" % (s3object))
                    time.sleep(10)
                    self.try_open(s3bucket = s3bucket, s3object = s3object)
                else:
                    return bRCs['bRC_Error']
            return bRCs['bRC_OK']

        elif IOP.func == bIOPS['IO_CLOSE']:
            bareosfd.DebugMessage(context, 100, "Closing file " + "\n")
            sp = str(self.FNAME).split('/',3)
            s3object = sp[3]
            if s3object == '':
                # This is the synthetic entry when there are no files in bucket.  Do nothing and be happy.
                return bRCs['bRC_OK']
            ConnMan.put(self.req['conn'])
            return bRCs['bRC_OK']

        elif IOP.func == bIOPS['IO_SEEK']:
            return bRCs['bRC_OK']

        elif IOP.func == bIOPS['IO_READ']:
            bareosfd.DebugMessage(
                context, 200, "Reading %d from file %s\n" %
                (IOP.count, self.FNAME))

            IOP.buf = bytearray(IOP.count)
            IOP.io_errno = 0
            try:
                lol = self.req['resp'].read(IOP.count)
                IOP.buf[:] = lol
                IOP.status = len(lol)
            except:
                IOP.status = -1
                return bRCs['bRC_Error']

            return bRCs['bRC_OK']

        elif IOP.func == bIOPS['IO_WRITE']:
            bareosfd.DebugMessage(context, 200, "Plugin does not support restore\n")
            IOP.status = -1
            return bRCs['bRC_Error']

# vim: ts=4 tabstop=4 expandtab shiftwidth=4 softtabstop=4
