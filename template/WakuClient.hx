package;
import WakuCommon;

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
          m_commandNo  = {{'data[0]'|cast('Int')}};
          var functionNo = {{'data[1]'|cast('Int')}};
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

  private function handshakeReply(data:Dynamic):Void {
    if(data.length != 2) return;
    try {
      m_handshaked = {{'data[0]'|cast('Bool')}};
      m_commandNo  = {{'data[1]'|cast('Int')}};
      if(m_handshaked == false) throw "reject";

      m_functions = new IntHash<Dynamic->Void>();
      {% for function in StoC %}
      m_functions.set({{function.id}}, call_{{function.name}});
      {% endfor %}

      onopen();
    }
    catch(errorMsg:String) error("handshake error[" + errorMsg + "]");
  }

//====================================================================================
  {% for function in StoC %}
  private function call_{{function.name}}(args:Dynamic) {
    if(args.length != {{function.args|length}}) return;
    var tmp:Dynamic;
    {% for arg in function.args %}
    {% if arg.is_array %}
    tmp = {{loop.index0|to_arg}};
    var {{arg.name}} = new {{arg.type}}();
    for(i in 0...tmp.length) {{arg.name}}.push({{"tmp[i]"|cast(arg.elementtype)}});
    {% else %}
    var {{arg.name}}:{{arg.type}} = {{loop.index0|to_arg|cast(arg.type)}};
    {% endif %}
    {% endfor %}
    {{function.name}}({% for arg in function.args %}{{arg.name}}{% if not loop.last %}, {% endif %}{% endfor %});
  }
  public function {{function.name}}({% for arg in function.args %}{{arg.name}}:{{arg.type}}{% if not loop.last %}, {% endif %}{% endfor %}):Void {}
  {% endfor %}
//====================================================================================

//====================================================================================
  {% for function in CtoS %}
  public function {{function.name}}({% for arg in function.args %}{{arg.name}}:{{arg.type}}{% if not loop.last %}, {% endif %}{% endfor %}):Bool {
    if(!m_handshaked) return false;
    m_socket.emit('message', [++m_commandNo, {{function.id}}, [
    {% for arg in function.args %}
    {% if arg.type == 'String' %}
    Sanitizer.run({{arg.name}})
    {% elif arg.type == 'Array<String>' %}
    Lambda.array(Lambda.map({{arg.name}}, Sanitizer.run))
    {% elif arg.type is classname %}
    {{arg.name}}.to_array()
    {% else %}
    {{arg.name}}
    {% endif %}
    {% if not loop.last %},{% endif %}
    {% endfor %}
    ]]);
    return true;
  }
  {% endfor %}
//====================================================================================

  public function onopen():Void {}
  public function error(msg:String):Void {}
  public function onclose():Void {}
  public function connectFailed():Void {}
}
