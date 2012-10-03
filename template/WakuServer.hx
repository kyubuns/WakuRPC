package;
import Lambda;
import js.Node;
import WakuCommon;

class Server {
  private var m_io:SocketIO;

  public function new():Void {}
  public function listen(port:Int, option:Dynamic, connection:Class<Connection>) {
    m_io = Node.require('socket.io').listen(port, option);
    m_io.sockets.on('connection', function(socket:Socket) {
      trace('connection');
      var con:Connection = Type.createInstance(connection , [socket]);
    });
  }
}

class Connection {
  private var m_socket:Socket;
  private var m_handshaked:Bool;
  private var m_commandNo:Int;
  private var m_functions:IntHash<Dynamic->Void>;

  public function new(socket:Socket):Void {
    m_socket = socket;
    m_socket.on('message', function (data:Dynamic) {
      if(data.length != 3) return;
      try {
        var commandNo  = {{'data[0]'|cast('Int')}};
        if(m_handshaked == false) return;
        m_commandNo++;
        if(m_commandNo == 1000) m_commandNo = 0;
        if(commandNo != m_commandNo) throw "wrong command NO. Actual-"+Std.string(commandNo)+", m_commandNo-" + Std.string(m_commandNo);
        m_commandNo = commandNo;

        var functionNo = {{'data[1]'|cast('Int')}};
        var args:Dynamic = data[2];
        var func = m_functions.get(functionNo);
        if(func == null) throw "non-existent function - " + Std.string(functionNo);
        func(args);
      }
      catch(errorMsg:String) {
        trace("wrong data received ["+errorMsg+"]");
        socket.disconnect();
      }
      catch( unknown : Dynamic ) {
        trace("Unknown exception : "+Std.string(unknown));
      }
    });

    m_socket.on('handshake', handshakeRequest);
    socket.on('disconnect', onclose);
    m_handshaked = false;
    m_commandNo = -1024;
  }

  private function handshakeRequest(data:Dynamic) {
    try {
      var protocolhash = {{'data'|cast('String')}};
      if(protocolhash != '{{yuuversion}}') throw "wrong version";
      trace("handshake ok");
      m_handshaked = true;
      m_commandNo = -1;//handshakeで0を返すと次にClientから返ってくる値は-1 + 1のため
    }
    catch(errorMsg:String) trace("handshake error[" + errorMsg + "]");

    m_socket.emit('handshake', [m_handshaked, 0]);
    if(m_handshaked == false) {
      m_socket.disconnect();
      return;
    }

    m_functions = new IntHash<Dynamic->Void>();
    {% for function in CtoS %}
    m_functions.set({{function.id}}, call_{{function.name}});
    {% endfor %}

    onopen();
  }

//====================================================================================
  {% for function in CtoS %}
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
  {% for function in StoC %}
  public function {{function.name}}({% for arg in function.args %}{{arg.name}}:{{arg.type}}{% if not loop.last %}, {% endif %}{% endfor %}):Bool {
    if(!m_handshaked) return false;
    m_socket.emit('message', [m_commandNo, {{function.id}}, [
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
  public function onclose():Void {}
}
