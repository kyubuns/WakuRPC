# coding: utf-8
import yaml
from jinja2 import FileSystemLoader, Environment
import sha
import sys
import random
import codecs

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

#手抜き
if len(sys.argv) != 4:
  print 'usagee python generator.py [yuu_file] [template_file] [output_filename]'
  quit(1)

yuu_filename = sys.argv[1]
template_filename = sys.argv[2]
output_filename = sys.argv[3]

yuu = yaml.load(open(yuu_filename).read())
env = Environment(loader=FileSystemLoader("."))

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
      if arg[1] == 'Int' or arg[1] == 'Float' or arg[1] == 'Bool':
        tmp.append({'name':arg[0], 'type':arg[1], 'kind':0})
      elif arg[1] == 'String':
        tmp.append({'name':arg[0], 'type':arg[1], 'kind':1})
      #ToDo:Array型
      #elif arg[1] == Array && (arg[1] == 'Int' or arg[1] == 'Float' or arg[1] == 'Bool' or arg[1] == 'String'):
      #ToDo:ユーザー定義Class/Enum
      #elif ユーザー定義型
      else:
        throw ("unknown type - " +arg[1])

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
