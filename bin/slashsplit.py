import sys
for line in sys.stdin:
    part = line.split('/')[0].strip()
    if len(part):
        print part
