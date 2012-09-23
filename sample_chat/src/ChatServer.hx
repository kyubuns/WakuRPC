import Std;
import js.Node;
import WakuServer;
import WakuCommon;

@:native("setInterval")
extern class SetInterval {
  function new(f:Void->Void, interval:Int) : Void;
}

class Client extends Connection{
  private static var nextId:Int = 0;
  public static var clients = new IntHash<Client>();

  private var myid:Int;
  override public function onopen():Void {
    myid = nextId++;
    clients.set(myid, this);

    trace("onopen - ID:" + Std.string(myid));
    for(con in Client.clients) con.info("ID:"+Std.string(myid)+"さんが来たよ〜", []);
  }

  override public function onclose():Void {
    clients.remove(myid);
    trace("onclose - ID:" + Std.string(myid));
    for(con in Client.clients) con.info("ID:"+Std.string(myid)+"さんが帰ったよ〜", []);
  }

  override public function chat(msg:Msg):Void {
    if(msg.name == "" || msg.msg == "") return;
    for(con in clients) con.chatNotify(myid, msg.name, msg.msg);
  }

}

class ChatServer {
  static var next_id = 0;
  public static function main() {
    var server:Server = new Server();
    server.listen(9876, {'log level': 3, 'heartbeat interval': 120, 'close timeout': 180}, Client);

    new SetInterval(ChatServer.tick, 60000);
    tick();
  }

  public static function tick() {
    //ここから何も送られてこなくてもイベント発生させられる
    var fugaaaa:String = Std.string(Lambda.count(Client.clients));
    trace("tick" + fugaaaa);
    var member = new Array<String>();
    member.push("aaa");
    member.push("bbb");
    member.push("ccc");
    for(con in Client.clients) con.info("現在"+fugaaaa+"人が接続中。", member);
  }
}
