import Std;
import js.JQuery;
import js.Lib;
import WakuClient;

class Client extends Connection {
  override public function onopen():Void {
    ChatClient.addtext("<b>サーバーに接続しました。</b>");
  }

  override public function connectFailed():Void {
    ChatClient.addtext("<b>サーバーに接続できませんでした。</b>");
  }

  override public function onclose():Void {
    ChatClient.addtext("<b>サーバーとの接続が切れました。</b>");
  }

  override public function error(msg:String):Void {
    ChatClient.addtext("<b>エラーが発生しました。["+ msg +"]</b>");
  }

  override public function chatNotify(id:Int, name:String, msg:String):Void {
    ChatClient.addtext(name + "(" + Std.string(id) + ") - " + msg);
  }
}

class ChatClient {
  static public function addtext(text:String):Void {
    new JQuery("div#chat").prepend("<div>" + text + "</div>");
  }

  static function main():Void {
    new JQuery(Lib.document).ready(function(e) {
      var con = new Client();
      ChatClient.addtext("<b>サーバーに接続中...</b>");
      con.connect('http://localhost:9876/');

      new JQuery("#send").click(function(){
        //ToDo: JQueryでテキストボックスから文字列受け取るのメソッド化する
        //(nullチェック中でやりたい)
        var name:String = new JQuery("#name").val();
        var msg:String = new JQuery("#message").val();
        if(name == "" || msg == "") return;
        con.chat(name, msg);
        new JQuery("#message").val("");
      });
    });
  }
}
