import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();
  runApp(
      ChangeNotifierProvider(create: (_) => AuthRepository(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        // Add the 3 lines from here...
        primaryColor: Colors.red,
      ), // ... to here.
      home: RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final List<WordPair> _suggestions = <WordPair>[]; // NEW
  final TextStyle _biggerFont = const TextStyle(fontSize: 18); // NEW
  var _saved = Set<WordPair>(); // NEW
  static bool disabledB = false;
  FirebaseAuth _auth;
  bool loggedin = false;
  String userID = "";
  String userEmail = "";
  bool validator1 = false;
  bool firstTime = false;
  favMaterialPageRoute() => MaterialPageRoute<void>(
    // NEW lines from here...
    builder: (BuildContext context) {
      Provider.of<AuthRepository>(context);
      final tiles = _saved.map(
            (WordPair pair) {
          return ListTile(
            title: Text(
              pair.asPascalCase,
              style: _biggerFont,
            ),
            trailing: Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            onTap: () {
              _saved.remove(pair);
              updateFirestore();

              setState(() {
                Provider.of<AuthRepository>(context, listen: false)
                    .Update();
              });
            },
          );
        },
      );
      final divided = ListTile.divideTiles(
        context: context,
        tiles: tiles,
      ).toList();

      return Scaffold(
        appBar: AppBar(
          title: Text('Saved Suggestions'),
        ),
        body: ListView(children: divided),
      );
    }, // ...to here.
  );

  void _pushSaved() {
    Navigator.of(context).push(
      favMaterialPageRoute(),
    );
  }

  loginMaterialPageRoute() => MaterialPageRoute<void>(
    // NEW lines from here...
    builder: (BuildContext context) {
      final welcomeText = Text("Welcome to Startup Names Generator, please log in below", style: _biggerFont,
      );
      final isLoggingIn = Provider.of<AuthRepository>(context).status;
      final emailCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      final confirmCtrl = TextEditingController();
      final Email = TextFormField(
        decoration: InputDecoration(labelText: 'Email'),
        controller: emailCtrl,
      );
      final Password = TextFormField(
        decoration: InputDecoration(labelText: 'Password'),
        controller: passwordCtrl,
      );
      final loginButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
              side: BorderSide(color: Color.fromRGBO(0, 160, 227, 1))),
          padding: EdgeInsets.all(10.0),
          primary: Colors.red,
          onPrimary: Colors.white,
        ),
        onPressed: isLoggingIn == Status.Authenticating
            ? null
            : () async {
          Provider.of<AuthRepository>(context, listen: false)
              .Authenticating();
          String email = emailCtrl.text;
          String password = passwordCtrl.text;
          bool bool_t = false;
          FocusScope.of(context).unfocus();
          _auth = FirebaseAuth.instance;

          try {
            await _auth.signInWithEmailAndPassword(
                email: email, password: password);
            bool_t = true;
          } catch (e) {}

          disabledB = false;

          if (bool_t) {
            loggedin = true;
            userID = _auth.currentUser.uid;
            userEmail = _auth.currentUser.email;
            try {
              imageLink = await FirebaseStorage.instance.ref()
                  .child(userID)
                  .getDownloadURL();
            }
            catch(e){
            }
            await updateFirestoreOnLogin();
            await updateFirestore();
            Provider.of<AuthRepository>(context, listen: false)
                .Authenticated();
            Navigator.of(context).pop();
            setState(() {
              //build(context);
            });
          } else {
            //Login FAILED
            userID = "";
            userEmail = "";
            final snackBar = SnackBar(
                content:
                Text("There was an error logging into the app"));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            Provider.of<AuthRepository>(context, listen: false)
                .Unauthenticated();
          }
        },
        child: Text("Login",
            style: TextStyle(fontSize: 15)),
      );

      final signupButton = ElevatedButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: 200,
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('Please confirm your password below:'),
                        TextFormField(
                          autovalidateMode: AutovalidateMode.always,
                          validator: (String val)=>val==passwordCtrl.text?null:"Passwords must match",
                          decoration: InputDecoration(labelText: 'Password:'),
                          controller: confirmCtrl,
                        ),
                        ElevatedButton(
                          child: const Text('Confirm'),
                          onPressed: () async {
                            _auth = FirebaseAuth.instance;
                            var bool_t = false;
                            var email = emailCtrl.text;
                            var confirmPassword = confirmCtrl.text;
                            var password=passwordCtrl.text;
                            if(confirmPassword==password){
                              try {
                                await _auth.createUserWithEmailAndPassword(
                                    email: email, password: password);
                                bool_t = true;
                                firstTime = true;
                              } catch (e) {}

                              if (bool_t) {
                                loggedin = true;
                                userID = _auth.currentUser.uid;
                                userEmail = _auth.currentUser.email;
                                await updateFirestoreOnLogin();
                                await updateFirestore();
                                Provider.of<AuthRepository>(context, listen: false)
                                    .Authenticated();
                                Navigator.of(context).pop();
                                setState(() {
                                });
                              } else {
                                userID = "";
                                userEmail = "";
                                final snackBar = SnackBar(
                                    content:
                                    Text("There was an error signing up"));
                                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                Provider.of<AuthRepository>(context, listen: false)
                                    .Unauthenticated();
                              }
                              Navigator.pop(context);
                            }
                            else{
                            }
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
                side: BorderSide(color: Color.fromRGBO(0, 160, 227, 1))),
            padding: EdgeInsets.all(10.0),
            primary: Colors.green,
            onPrimary: Colors.white,
          ),
          child: Text("New user? Click to sign up"));
      return Scaffold(
          appBar: AppBar(
            title: Text('Login'),
          ),
          body: Column(children: [
            welcomeText,
            Email,
            Password,
            loginButton,
            signupButton
          ]));
    }, // ...to here.
  );

  void _pushLogin() {
    Navigator.of(context).push(
      loginMaterialPageRoute(),
    );
  }

  Future<void> signOut() async {
    await updateFirestore();
    _saved = {};
    await _auth.signOut();
    loggedin = false;
    firstTime = false;
    imageLink="";
    userID = "";
    userEmail = "";
    setState(() {
      //build(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Startup Name Generator'),
        actions: [
          IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
          IconButton(
              icon: loggedin ? Icon(Icons.exit_to_app) : Icon(Icons.login),
              onPressed: loggedin ? signOut : _pushLogin),
        ],
      ),
      body: _buildSuggestions(),
    );
  }

  Future<void> updateFirestoreOnLogin() async {
    List<dynamic> firstsList = [];
    List<dynamic> secondsList = [];
    DocumentSnapshot retrieve;
    Map data;
    CollectionReference database =
    FirebaseFirestore.instance.collection('Users');
    //---- Retrieval ----
    try {
      retrieve = await database.doc(userID).get();
      data = retrieve.data();
      firstsList = data['firstSavedList'];
      secondsList = data['secondSavedList'];
      var i = 0;
      for (String s1 in firstsList) {
        _saved.add(WordPair(s1, secondsList[i]));
        i += 1;
      }
    } catch (e) {
      print("We were here!!");
    }

  }

  Future<void> updateFirestore() async {
    if (userID == "") {
      return;
    }
    List<String> firstsList = [];
    List<String> secondsList = [];

    CollectionReference database =
    await FirebaseFirestore.instance.collection('Users');

    for (WordPair p in _saved) {
      firstsList.add(p.first);
      secondsList.add(p.second);
    }
    if (firstTime){
      print("Trying this");
      await database.doc(userID).set({'firstSavedList': firstsList, 'secondSavedList': secondsList});
    }
    else {
      print("Trying this2");
      await database.doc(userID)
          .update(
          {'firstSavedList': firstsList, 'secondSavedList': secondsList});
    }
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        // NEW lines from here...
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
            updateFirestore();
          } else {
            _saved.add(pair);
            updateFirestore();
          }
        });
      }, // ... to here.
    );
  }

  bool position = false;
  String imageLink = "";
  Widget _buildSuggestions() {
    return userID != "" ? Scaffold(
      body: GestureDetector(
        onTap: () {
          position = !position;
          setState(() {});
        },
        child: SnappingSheet(
          grabbingHeight: 65,
          grabbing: Container(
            color: Colors.grey,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("      Welcome Back,  " + userEmail,
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          fontSize: 16)),
                  Container(
                      child: Icon(
                        Icons.keyboard_arrow_up_outlined,
                        color: Colors.white,
                        size: 24,
                      ))
                ]),
          ),
          snappingPositions: [
            SnappingPosition.pixels(positionPixels: 30),
            SnappingPosition.pixels(positionPixels: 180),
          ],
          sheetBelow: SnappingSheetContent(
              child: Container(
                color: Colors.white,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                          width: 100,
                          height: 100,
                          child: Image(
                            image: NetworkImage(imageLink != ""
                                ? imageLink
                                : 'https://uxwing.com/wp-content/themes/uxwing/download/07-design-and-development/image-not-found.png'),
                          )),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(userEmail,
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                  fontSize: 24)),
                          TextButton(
                            style: TextButton.styleFrom(
                              primary: Colors.white,
                              shadowColor: Colors.grey,
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.all(8.0)),
                            onPressed: () async {
                              File _image;
                              final picker = ImagePicker();
                              var pickedFile = await picker.getImage(source: ImageSource.gallery);
                              if (pickedFile != null) {
                                _image = File(pickedFile.path);
                                await FirebaseStorage.instance.ref().child(userID).putFile(_image);
                                imageLink= await FirebaseStorage.instance.ref().child(userID).getDownloadURL();
                                setState(() {
                                });
                              }
                              else {
                                final snackBar = SnackBar(
                                    content:
                                    Text("No image selected"));
                                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                              }

                            },
                            child: Text(
                              "Change avatar",
                              style: TextStyle(fontSize: 20.0),
                            ),
                          )
                        ],
                      )
                    ]),
              ),
            ),
          child: ListView.builder(
              padding: const EdgeInsets.all(16),
              // The itemBuilder callback is called once per suggested
              // word pairing, and places each suggestion into a ListTile
              // row. For even rows, the function adds a ListTile row for
              // the word pairing. For odd rows, the function adds a
              // Divider widget to visually separate the entries. Note that
              // the divider may be difficult to see on smaller devices.
              itemBuilder: (BuildContext _context, int i) {
                // Add a one-pixel-high divider widget before each row
                // in the ListView.
                if (i.isOdd) {
                  return Divider();
                }

                // The syntax "i ~/ 2" divides i by 2 and returns an
                // integer result.
                // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
                // This calculates the actual number of word pairings
                // in the ListView,minus the divider widgets.
                final int index = i ~/ 2;
                // If you've reached the end of the available word
                // pairings...
                if (index >= _suggestions.length) {
                  // ...then generate 10 more and add them to the
                  // suggestions list.
                  _suggestions.addAll(generateWordPairs().take(10));
                }
                return _buildRow(_suggestions[index]);
              }),
        ),
      ),
    ) : ListView.builder(
        padding: const EdgeInsets.all(16),
        // The itemBuilder callback is called once per suggested
        // word pairing, and places each suggestion into a ListTile
        // row. For even rows, the function adds a ListTile row for
        // the word pairing. For odd rows, the function adds a
        // Divider widget to visually separate the entries. Note that
        // the divider may be difficult to see on smaller devices.
        itemBuilder: (BuildContext _context, int i) {
          // Add a one-pixel-high divider widget before each row
          // in the ListView.
          if (i.isOdd) {
            return Divider();
          }

          // The syntax "i ~/ 2" divides i by 2 and returns an
          // integer result.
          // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
          // This calculates the actual number of word pairings
          // in the ListView,minus the divider widgets.
          final int index = i ~/ 2;
          // If you've reached the end of the available word
          // pairings...
          if (index >= _suggestions.length) {
            // ...then generate 10 more and add them to the
            // suggestions list.
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        });
  }


}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User _user;
  Status _status = Status.Uninitialized;

  AuthRepository() {
    Firebase.initializeApp();
    _auth = FirebaseAuth.instance;
  }

  Status get status => _status;
  User get user => _user;

  void Authenticated() {
    _status = Status.Authenticated;
    notifyListeners();
  }

  void Authenticating() {
    _status = Status.Authenticating;
    notifyListeners();
  }

  void Unauthenticated() {
    _status = Status.Unauthenticated;
    notifyListeners();
  }

  void Update() {
    notifyListeners();
  }
}