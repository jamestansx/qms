# Queue Management System

## TODO
- [x] update queue to wearables to vibrate
- [x] fix bug where queue is not updating its priority

## SETUP

- User UI:
```sh
$ # To run the app
$ fvm flutter run --dart-define=BASEURL=xxxx
$ # To build the app
$ fvm flutter build apk --release --dart-define=BASEURL=xxxx
```

- Management UI:
```sh
$ # To run the app (optionally --release)
$ fvm flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 --dart-define=BASEURL=xxxx
```

- backend:
```sh
$ # To start the server
$ BASEURL=xxxx cargo run --release
```
