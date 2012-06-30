#!/usr/bin/env python
import json
import sys
jsonPath = sys.argv[1]
with open(jsonPath) as jsonFile:
    jsonDict = json.load(jsonFile)
    print "v" + jsonDict["engines"]["node"]
