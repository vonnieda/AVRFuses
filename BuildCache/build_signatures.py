#!/usr/bin/python
# -*- coding: utf-8 -*-
import os

import sys


if len(sys.argv) != 2:
	print 'Usage: build_signatures.py <path to AVR Studio devices directory>'
	sys.exit(1)

atmel_location = sys.argv[1]

sys.stdout = open('Signatures.lst', 'w')


def process_atdf(path):
    with open(path) as f:
        lines = f.readlines()
        name = None
        s1 = None
        s2 = None
        s3 = None
        l = len('<property name="SIGNATURE0" value="')
        for s in lines:
            pn = s.find('<device name="')
            if pn >= 0:
                name = s[pn+len('<device name="'):]
                name = name[:name.find('"')]
            p1 = s.find('<property name="SIGNATURE0" value="')
            if p1 >= 0:
                s1 = s[p1+l:-4]
            p2 = s.find('<property name="SIGNATURE1" value="')
            if p2 >= 0:
                s2 = s[p2+l:-4]
            p3 = s.find('<property name="SIGNATURE2" value="')
            if p3 >= 0:
                s3 = s[p3+l:-4]
        print name + "," + s1 + "," + s2 + "," + s3

for filename in os.listdir(atmel_location):
    if filename.endswith(".atdf"):
        path = os.path.join(atmel_location, filename)
        process_atdf(path)


