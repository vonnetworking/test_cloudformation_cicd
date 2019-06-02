#!/usr/bin/env python

import yaml
import sys
import re
import pprint

file_name = sys.argv[1]

# Some tags need to be ignored
def ignore_tag_constructor(loader, tag, node):
    return None

# Ignore tags starting with !
yaml.add_multi_constructor('!', ignore_tag_constructor, Loader=yaml.SafeLoader)

stream = file(file_name, 'r')
raw_content = stream.read()
filtered_content = re.sub(r'\t', ' ', raw_content)
yaml_obj = yaml.safe_load(filtered_content)

owner = None
if 'Metadata' in yaml_obj and 'Owner' in yaml_obj['Metadata']:
    owner = yaml_obj['Metadata']['Owner']

if owner:
    print owner
