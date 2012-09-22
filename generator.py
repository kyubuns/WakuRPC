# coding: utf-8
import yaml
from jinja2 import FileSystemLoader, Environment
import sha
import sys
import random
import codecs

# sha1
def hashfile(fileName, hashObject):
  fileObject = open(fileName, 'rb')
  try:
    while True:
      chunk = fileObject.read(65536)
      if not chunk: break
      hashObject.update(chunk)
  finally:
    fileObject.close()
  return hashObject.hexdigest()

def sha1file(fileName):
  hashObject = sha.new()
  return hashfile(fileName, hashObject)



#custom filters
def cast(value, arg_type):
  if arg_type == 'Int' or arg_type == 'Float' or arg_type == 'Bool':
    return "cast(" + value + ", " + arg_type + ")"
  elif arg_type == 'String':
    return "sanitize(cast(" + value + ", " + arg_type + "))"
  else:
    return "siran"
def to_arg(value):
  return "args[" + str(value) + "]"


#main
if len(sys.argv) != 4:
  print 'usagee python generator.py [yuu_file] [template_file] [output_filename]'
  quit(1)

yuu_filename = sys.argv[1]
template_filename = sys.argv[2]
output_filename = sys.argv[3]

yuu = yaml.load(open(yuu_filename).read())
env = Environment(loader=FileSystemLoader("."))
env.filters['cast'] = cast
env.filters['to_arg'] = to_arg

random.seed(sha1file(yuu_filename))
random_ids = range(1000, 10000)
random.shuffle(random_ids)

lists = {}
lists['C->S'] = []
lists['S->C'] = []
lists['enum'] = []
lists['struct'] = []

for name, args in yuu.items():
  type = args[0]
  output = {
    'name' : name,
    'type' : type,
    'id'   : random_ids[-1]
  }
  random_ids.pop()
  tmp = []
  for arg in args[1:]:
    if type == 'enum':
      tmp.append(arg[0])
    else:
      if arg[1] == 'Array':
        tmp.append({'name':arg[0], 'type':'Array<'+arg[2]+'>', 'elementtype':arg[2], 'is_array':True})
      else:
        tmp.append({'name':arg[0], 'type':arg[1], 'is_array':False})

  output['args'] = tmp
  lists[type].append(output)

template = env.get_template(template_filename)
f = open(output_filename, 'w')
f = codecs.lookup('utf_8')[-1](f)
f.write(template.render(
  CtoS       = lists['C->S'],
  StoC       = lists['S->C'],
  enum       = lists['enum'],
  struct     = lists['struct'],
  yuuversion = sha1file(yuu_filename)
  ))
f.close()
