package;

@:native("io")
extern class IO {
  static function connect(host:String, ?option:Dynamic):Socket;
}

extern class SocketIO {
  var sockets : Sockets;
  function set(name:String, option:Dynamic):Void;
}

extern class Sockets {
  function on(event:String, handler:Socket->Void) : Void;
}

extern class Socket {
  function emit(event:String, data:Dynamic) : Void;
  @:overload(function (event:String, handler:Void->Void):Void{})
  function on(event:String, handler:Dynamic->Void) : Void;
  function disconnect() : Void;
}

{% for struct in structs %}
class {{struct.name}} {
  public function new({% for arg in struct.args %}{% if not loop.first %}, {% endif %}{{arg.name}}_:{{arg.type}}{% endfor %}) {
    {% for arg in struct.args %}
    {{arg.name}} = {{arg.name}}_;
    {% endfor %}
  }

  public static function create(args:Dynamic):{{struct.name}} {
    trace(args);
    trace(args.length);
    if(args.length != {{struct.args|length}}) throw "new {{struct.name}} : wrong args";

    var tmp = new {{struct.name}}(
      {% for arg in struct.args %}
      {{loop.index0|to_arg|cast(arg.type)}}{% if not loop.last %},{% endif %}
      {% endfor %}
    );
    return tmp;
  }

  public function to_array():Array<Dynamic> {
    var tmp = new Array<Dynamic>();
    {% for arg in struct.args %}
    {% if arg.type == 'String' %}
    tmp.push(Sanitizer.run({{arg.name}}));
    {% elif arg.type == 'Array<String>' %}
    tmp.push(Lambda.array(Lambda.map({{arg.name}}, Sanitizer.run)));
    {% elif arg.type is classname %}
    tmp.push({{arg.name}}.to_array());
    {% else %}
    tmp.push({{arg.name}});
    {% endif %}
    {% endfor %}
    return tmp;
  }

  {% for arg in struct.args %}
  public var {{arg.name}}:{{arg.type}};
  {% endfor %}
}
{% endfor %}

class Sanitizer {
  static public function run(str:String):String {
    str = StringTools.replace(str, "<", '&lt;');
    str = StringTools.replace(str, ">", '&gt;');
    str = StringTools.replace(str, '"', '&quot;');
    str = StringTools.replace(str, "'", '&apos;');
    return str;
  }
}

