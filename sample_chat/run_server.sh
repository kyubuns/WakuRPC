set -e
cd ../
python generator.py sample_chat/chat.yuu template/WakuClient.hx sample_chat/src/WakuClient.hx
python generator.py sample_chat/chat.yuu template/WakuServer.hx sample_chat/src/WakuServer.hx
python generator.py sample_chat/chat.yuu template/WakuCommon.hx sample_chat/src/WakuCommon.hx
cd sample_chat
haxe compile.hxml
node bin/chat_server.js
