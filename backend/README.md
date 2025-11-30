# Backend

Uses Firebase & Google Cloud Functions.

To deploy, install the Firebase CLI:
<https://firebase.google.com/docs/cli#install_the_firebase_cli>

You'll probably have to log in too.  Then, run:

```sh
firebase deploy
```

...but this takes an eternity.  For testing it's faster to run

```sh
firebase emulators:start
```

Choose the right cloudfunctions.net(production)/localhost(testing) baseURL in the app's config.dart file.
Then you can just edit the file and the functions update automatically.