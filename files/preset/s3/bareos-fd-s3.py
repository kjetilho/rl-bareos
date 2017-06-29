#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Provided by the Bareos FD Python plugin interface
from bareosfd import *
from bareos_fd_consts import *

import BareosFdWrapper
# This module contains the wrapper functions called by the Bareos-FD, the functions call the corresponding
# methods from your plugin class
from BareosFdWrapper import *

# This module contains the used plugin class
from BareosFdPluginS3 import *

def load_bareos_plugin(context, plugindef):
    '''
    This function is called by the Bareos-FD to load the plugin
    We use it to instantiate the plugin class
    '''
    # BareosFdWrapper.bareos_fd_plugin_object is the module attribute that holds the plugin class object
    BareosFdWrapper.bareos_fd_plugin_object = BareosFdPluginS3 (context, plugindef);
    return bRCs['bRC_OK'];

# the rest is done in the Plugin module
