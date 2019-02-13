# This file is for the mdl gem
# https://github.com/markdownlint/markdownlint
all
exclude_rule 'MD012' # Multiple consecutive blank lines
rule 'MD003', :style => :setext_with_atx
rule 'MD029', :style => :ordered
rule 'MD046', :style => :consistent
