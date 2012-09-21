package;
import Common;

class Connection {
  private var m_socket:Socket;
  private var m_handshaked:Bool;
  private var m_commandNo:Int;
  private var m_functions:IntHash<Dynamic->Void>;

  public function new():Void {}
  public function connect(host:String):Void {
    m_socket = IO.connect(host, { reconnect:false, 'connect timeout': 1000 });
    m_socket.on('error', function(){ error("socket error"); });
    m_socket.on('connect_failed', connectFailed);
    m_socket.on('connect', function() {
      m_socket.on('disconnect', onclose);
      m_socket.on('message', function(data:Dynamic) {
        if(m_handshaked == false) return;
        if(data.length != 3) return;
        try {
          m_commandNo  = cast(data[0], Int);
          var functionNo = cast(data[1], Int);
          var args:Dynamic = data[2];
          var func = m_functions.get(functionNo);
          if(func == null) throw "non-existent function";
          func(args);
        }
        catch(errorMsg:String) {
          //クライアント側は変なデータきてもそのデータ無視するだけで。
          trace("wrong data received ["+errorMsg+"]");
        }
      });
      m_socket.on('handshake', handshakeReply);
      m_socket.emit('handshake', '{{yuuversion}}');
      m_handshaked = false;
      m_commandNo = -1024;
    });
  }

  static private function sanitize(str:String):String {
    str = StringTools.replace(str, "<", '&lt;');
    str = StringTools.replace(str, ">", '&gt;');
    str = StringTools.replace(str, '"', '&quot;');
    str = StringTools.replace(str, "'", '&apos;');
    return str;
  }

  private function handshakeReply(data:Dynamic):Void {
    if(data.length != 2) return;
    try {
      m_handshaked = cast(data[0], Bool);
      m_commandNo  = cast(data[1], Int);
      if(m_handshaked == false) throw "reject";

      m_functions = new IntHash<Dynamic->Void>();
      {% for function in StoC %}
      m_functions.set({{function.id}}, call_{{function.name}});
      {% endfor %}

      onopen();
    }
    catch(errorMsg:String) error("handshake error");
  }

//====================================================================================
  {% for function in StoC %}
  private function call_{{function.name}}(args:Dynamic) {
    if(args.length != {{function.args|length}}) return;
    {% for arg in function.args %}
    {% if arg.kind == 0 %}
    var {{arg.name}}:{{arg.type}} = cast(args[{{loop.index0}}], {{arg.type}});
    {% elif arg.kind == 1 %}
    var {{arg.name}}:{{arg.type}} = sanitize(cast(args[{{loop.index0}}], {{arg.type}}));
    {% endif %}
    {% endfor %}
    {{function.name}}({% for arg in function.args %}{% if not loop.first %}, {% endif %}{{arg.name}}{% endfor %});
  }
  public function {{function.name}}({% for arg in function.args %}{% if not loop.first %}, {% endif %}{{arg.name}}:{{arg.type}}{% endfor %}):Void {}
  {% endfor %}
//====================================================================================

//====================================================================================
  {% for function in CtoS %}
  public function {{function.name}}({% for arg in function.args %}{% if not loop.first %}, {% endif %}{{arg.name}}:{{arg.type}}{% endfor %}):Bool {
    if(!m_handshaked) return false;
    {% for arg in function.args %}
    {% if arg.kind == 0 %}
    var {{arg.name}}_:{{arg.type}} = cast({{arg.name}}, {{arg.type}});
    {% elif arg.kind == 1 %}
    var {{arg.name}}_:{{arg.type}} = sanitize(cast({{arg.name}}, {{arg.type}}));
    {% endif %}
    {% endfor %}
    m_socket.emit('message', [++m_commandNo, {{function.id}}, [{% for arg in function.args %}{% if not loop.first %}, {% endif %}{{arg.name}}_{% endfor %}]]);
    return true;
  }
  {% endfor %}
//====================================================================================

  public function onopen():Void {}
  public function error(msg:String):Void {}
  public function onclose():Void {}
  public function connectFailed():Void {}
}
