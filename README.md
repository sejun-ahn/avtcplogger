# avtcplogger
TCP Client Video Recording iOS Application

## Comment
Receiving message with flag `a`, start recording.\
Receiving message with flag `b`, stop recording.

You can change the flag on [this line](https://github.com/sejun-ahn/avtcplogger/blob/db1ef66c093dbd21049fa5f84ef895617ecf5aa5/avtcplogger/View/ContentView.swift#L38))\
And for the seperator(default: `;`), on [this line](https://github.com/sejun-ahn/avtcplogger/blob/db1ef66c093dbd21049fa5f84ef895617ecf5aa5/avtcplogger/Manager/SocketManager.swift#L177).

The resolution of the video is fixed with `.hd1920x1080`.\
The exposure duration is also fixed with `setShutterSpeed()`.
