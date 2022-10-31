import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

import "../utils/appBar.dart";

bool _darkTheme = false;

class GlobalSearchFav with ChangeNotifier {
  String _globalSearchValue = "";

  String get globalSearchValue => _globalSearchValue;

  void changeGlobalSearchValue(value) {
    _globalSearchValue = value;

    notifyListeners();
  }
}

class LoadContactFav with ChangeNotifier {
  Future<List<FavContact>>? _allContacts;

  Future<List<FavContact>>? get allContacts => _allContacts;

  void changeAllContacts(value) {
    _allContacts = value;
    notifyListeners();
  }

  /// Makes `Counter` readable inside the devtools by listing all of its properties

}

// Future to archive contacts or not
Future updateArch(archId, archive, context) async {
  var postUri = Uri.parse(
      "http://10.0.2.2:8000/contact/edit/arch/$archId"); // this variable catches the url of the server where the contact will be saved

  http.MultipartRequest request = http.MultipartRequest("POST",
      postUri); // this http mulipartrequest variable creates a post instance to the server

  // the datas which will be sent to the server
  request.fields["isArch"] = "$archive";

  // this http streamresponse variable make it possible to send all data to the server if everything is ok
  // ignore: unused_local_variable
  final http.StreamedResponse response = await request.send();

  Navigator.of(context).pushNamed('/fav_contact');
}

// Future to make contacts favorite or not
Future<void> updateFav(favId, favorite) async {
  var postUri = Uri.parse(
      "http://10.0.2.2:8000/contact/edit/fav/$favId"); // this variable catches the url of the server where the contact will be saved

  http.MultipartRequest request = http.MultipartRequest("POST",
      postUri); // this http mulipartrequest variable creates a post instance to the server

  // the datas which will be sent to the server
  request.fields["isFav"] = "$favorite";

  // this http streamresponse variable make it possible to send all data to the server if everything is ok
  // ignore: unused_local_variable
  final http.StreamedResponse response = await request.send();
}

// A future to get all the contacts
Future<List<FavContact>> fetchFavContacts(
    http.Client client, context, lang) async {
  final response = await client.get(Uri.parse('http://10.0.2.2:8000/favs'),
      headers: {
        "Connection": "Keep-Alive",
        "Keep-Alive": "timeout=5, max=1000"
      }).timeout(
    const Duration(seconds: 3),
    onTimeout: () {
      // Time has run out, do what you wanted to do.
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: _darkTheme ? Color(0XFF1F1F30) : null,
          title: Text(
              lang == "fr" ? 'Erreur de connexion' : 'Internet error 🌍',
              style: TextStyle(color: _darkTheme ? Colors.white : null)),
          content: Text(
              lang == "fr"
                  ? 'Vérifiez votre connexion internet'
                  : "Check your internet connexion",
              style: TextStyle(color: _darkTheme ? Colors.white : null)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      throw ("big error 404"); // Request Timeout response status code
    },
  );

  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parseFavContacts, response.body);
}

// A function that converts a response body into a List<Photo>.
List<FavContact> parseFavContacts(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<FavContact>((json) => FavContact.fromJson(json)).toList();
}

class FavContact {
  final int id;
  final String nom;
  final String prenoms;
  final String email;
  final String phone;
  final String photo;
  final bool isFav;
  final bool isArch;

  const FavContact({
    required this.id,
    required this.nom,
    required this.prenoms,
    required this.email,
    required this.phone,
    required this.photo,
    required this.isFav,
    required this.isArch,
  });

  factory FavContact.fromJson(Map<String, dynamic> json) {
    return FavContact(
      id: json['id'] as int,
      nom: json['nom'] as String,
      prenoms: json['prenoms'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      photo: json['photo'] ?? "aucun",
      isFav: json['is_fav'] == 1 ? true : false,
      isArch: json['is_arch'] == 1 ? true : false,
    );
  }
}

class FavContactList extends HookWidget {
  FavContactList({super.key});

  var sysLng = Platform.localeName.split('_')[0];

  @override
  Widget build(BuildContext context) {
    final future = useMemoized(SharedPreferences.getInstance);
    final snapshot = useFuture(future, initialData: null);
    context
        .read<LoadContactFav>()
        .changeAllContacts(fetchFavContacts(http.Client(), context, sysLng));
    var loadContact = context.watch<LoadContactFav>().allContacts;

    context.read<GlobalSearchFav>().changeGlobalSearchValue("");

    useEffect(() {
      final prefs = snapshot.data;
      if (prefs == null) {
        return;
      }
      sysLng = (prefs.getString('lang') ?? Platform.localeName.split('_')[0]);
      _darkTheme = (prefs.getBool('darkTheme') ?? false);
      return null;
    }, [snapshot.data]);

    return Scaffold(
      backgroundColor: _darkTheme ? Color(0XFF1F1F30) : null,
      appBar: DefaultAppBar(
          globalSearchValue: context.read<GlobalSearchFav>(),
          title: sysLng == "fr" ? 'Mes favoris' : 'My favorites'),
      drawer: Drawer(
        backgroundColor: _darkTheme ? Color(0XFF1F1F30) : null,
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("pictures/contact_up.png"),
                      fit: BoxFit.cover)),
              child: Text(""),
            ),
            ListTile(
              leading: Icon(Icons.home_outlined,
                  color: _darkTheme ? Colors.blueGrey : null),
              textColor: _darkTheme ? Colors.white : null,
              title: Text(sysLng == "fr" ? 'Accueil' : 'Home'),
              onTap: () {
                // Update the state of the app.
                // ...
                Navigator.pushNamed(context, '/home');
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite_outline),
              textColor: _darkTheme ? Colors.white : null,
              title: Text(sysLng == "fr" ? 'Mes favoris' : 'My favorites'),
              selected: true,
              selectedColor: const Color(0xFFF2B538),
              selectedTileColor: const Color(0xFFF2B538).withOpacity(0.2),
              onTap: () {
                // Update the state of the app.
                // ...
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.archive_outlined,
                  color: _darkTheme ? Colors.blueGrey : null),
              textColor: _darkTheme ? Colors.white : null,
              title: const Text('Archive'),
              onTap: () {
                // Update the state of the app.
                // ...
                Navigator.pushNamed(context, '/archsContact');
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outlined,
                  color: _darkTheme ? Colors.blueGrey : null),
              textColor: _darkTheme ? Colors.white : null,
              title: Text(sysLng == "fr" ? 'A propos' : 'About'),
              onTap: () {
                // Update the state of the app.
                // ...
                Navigator.pushNamed(context, '/aboutContact');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined,
                  color: _darkTheme ? Colors.blueGrey : null),
              textColor: _darkTheme ? Colors.white : null,
              title: Text(sysLng == "fr" ? 'Paramètres' : 'Settings'),
              onTap: () {
                // Update the state of the app.
                // ...
                Navigator.pushNamed(context, '/settingContact');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: FutureBuilder<List<FavContact>>(
          future: loadContact,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("pictures/no_internet.png"),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: Color(0xFFF2B538),
                        onPrimary: Color(0XFF142641)),
                    onPressed: () {},
                    child: Text(sysLng == "fr" ? "Actualiser" : "Refresh",
                        style: TextStyle(fontSize: 18)),
                  ),
                ],
              );
            } else if (snapshot.hasData) {
              return RefreshIndicator(
                  onRefresh: () async {
                    context.read<LoadContactFav>().changeAllContacts(
                        fetchFavContacts(http.Client(), context, sysLng));
                  },
                  child:
                      FavContactsItems(contacts: snapshot.data!, lang: sysLng));
            } else {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFF2B538)),
              );
            }
          },
        ),
      ),
    );
  }
}

// Class to set a pattern for the contacts.
class FavContactsItems extends HookWidget {
  const FavContactsItems({super.key, required this.contacts, this.lang});

  final List<FavContact> contacts;
  final lang;

  @override
  Widget build(BuildContext context) {
    var searchText = context.watch<GlobalSearchFav>().globalSearchValue;

    if (contacts.isNotEmpty) {
      if (context.watch<GlobalSearchFav>().globalSearchValue == "") {
        return ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            // ignore: prefer_const_constructors
            return Slidable(
                // Specify a key if the Slidable is dismissible.
                key: ValueKey(0),

                // The start action pane is the one at the left or the top side.
                startActionPane: ActionPane(
                  // A motion is a widget used to control how the pane animates.
                  motion: const ScrollMotion(),

                  // A pane can dismiss the Slidable.
                  dismissible: DismissiblePane(onDismissed: () {
                    updateArch(
                        contacts[index].id, contacts[index].isArch, context);
                  }),

                  // All actions are defined in the children parameter.
                  children: [
                    // A SlidableAction can have an icon and/or a label.
                    SlidableAction(
                      // An action can be bigger than the others.
                      flex: 2,
                      onPressed: (BuildContext context) {
                        updateArch(contacts[index].id, contacts[index].isArch,
                            context);

                        context.read<LoadContactFav>().changeAllContacts(
                            fetchFavContacts(http.Client(), context, lang));
                      },
                      backgroundColor: Color(0xFFF2B538),
                      foregroundColor: Colors.white,
                      icon: Icons.archive,
                      label: 'Archive',
                    ),
                  ],
                ),

                // The end action pane is the one at the right or the bottom side.
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  dismissible: DismissiblePane(onDismissed: () {
                    updateArch(
                        contacts[index].id, contacts[index].isArch, context);
                  }),
                  children: [
                    SlidableAction(
                      // An action can be bigger than the others.
                      flex: 2,
                      onPressed: (BuildContext context) {
                        updateArch(contacts[index].id, contacts[index].isArch,
                            context);

                        context.read<LoadContactFav>().changeAllContacts(
                            fetchFavContacts(http.Client(), context, lang));
                      },
                      backgroundColor: Color(0xFFF2B538),
                      foregroundColor: Colors.white,
                      icon: Icons.archive,
                      label: 'Archive',
                    ),
                  ],
                ),

                // The child of the Slidable is what the user sees when the
                // component is not dragged.
                child: ListTile(
                  onTap: () {
                    // push to viewContact route with some parameters
                    Navigator.pushNamed(context, '/viewContact',
                        arguments: {'id': contacts[index].id, 'route': "home"});
                  },
                  textColor: _darkTheme ? Colors.white : null,
                  leading: CachedNetworkImage(
                    imageUrl: "http://10.0.2.2:8000${contacts[index].photo}",
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      size: 48,
                    ),
                  ),
                  title: Text(
                    "${StringUtils.capitalize(contacts[index].prenoms)} ${StringUtils.capitalize(contacts[index].nom)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${contacts[index].phone}'),
                  trailing: IconButton(
                      icon: Icon(
                        contacts[index].isFav ? Icons.star : Icons.star_border,
                        color: contacts[index].isFav
                            ? Color(0xFFF2B538)
                            : Color(0XFF1F1F30),
                      ),
                      onPressed: () {
                        // If there is network, the datas are saved or else an alert error is shown
                        http.get(Uri.parse('http://10.0.2.2:8000/')).timeout(
                          const Duration(seconds: 1),
                          onTimeout: () {
                            // Time has run out, do what you wanted to do.
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: const Text('Internet error 🌍'),
                                content: const Text(
                                    'Vérifiez votre connexion internet'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'OK'),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            throw ("big error 404"); // Request Timeout response status code
                          },
                        ).whenComplete(() {
                          updateFav(
                            contacts[index].id,
                            contacts[index].isFav,
                          );

                          context.read<LoadContactFav>().changeAllContacts(
                              fetchFavContacts(http.Client(), context, lang));
                        });
                      }),
                ));
            //return Image.network(contacts[index].photo);
          },
        );
      } else {
        return ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            // ignore: prefer_const_constructors
            return contacts[index]
                        .nom
                        .toLowerCase()
                        .contains(searchText.toLowerCase()) ||
                    contacts[index]
                        .prenoms
                        .toLowerCase()
                        .contains(searchText.toLowerCase()) ||
                    contacts[index]
                        .phone
                        .toLowerCase()
                        .contains(searchText.toLowerCase())
                ? Slidable(
                    // Specify a key if the Slidable is dismissible.
                    key: ValueKey(0),

                    // The start action pane is the one at the left or the top side.
                    startActionPane: ActionPane(
                      // A motion is a widget used to control how the pane animates.
                      motion: const ScrollMotion(),

                      // A pane can dismiss the Slidable.
                      dismissible: DismissiblePane(onDismissed: () {
                        updateArch(contacts[index].id, contacts[index].isArch,
                            context);
                      }),

                      // All actions are defined in the children parameter.
                      children: [
                        // A SlidableAction can have an icon and/or a label.
                        SlidableAction(
                          // An action can be bigger than the others.
                          flex: 2,
                          onPressed: (BuildContext context) => updateArch(
                              contacts[index].id,
                              contacts[index].isArch,
                              context),
                          backgroundColor: Color(0xFFF2B538),
                          foregroundColor: Colors.white,
                          icon: Icons.archive,
                          label: 'Archive',
                        ),
                      ],
                    ),

                    // The end action pane is the one at the right or the bottom side.
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      dismissible: DismissiblePane(onDismissed: () {
                        updateArch(contacts[index].id, contacts[index].isArch,
                            context);
                      }),
                      children: [
                        SlidableAction(
                          // An action can be bigger than the others.
                          flex: 2,
                          onPressed: (BuildContext context) => updateArch(
                              contacts[index].id,
                              contacts[index].isArch,
                              context),
                          backgroundColor: Color(0xFFF2B538),
                          foregroundColor: Colors.white,
                          icon: Icons.archive,
                          label: 'Archive',
                        ),
                      ],
                    ),

                    // The child of the Slidable is what the user sees when the
                    // component is not dragged.
                    child: ListTile(
                      onTap: () {
                        // push to viewContact route with some parameters
                        Navigator.pushNamed(context, '/viewContact',
                            arguments: {
                              'id': contacts[index].id,
                              'route': "home"
                            });
                      },
                      textColor: _darkTheme ? Colors.white : null,
                      leading: CachedNetworkImage(
                        imageUrl:
                            "http://10.0.2.2:8000${contacts[index].photo}",
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: 48,
                        ),
                      ),
                      title: Text(
                        "${StringUtils.capitalize(contacts[index].prenoms)} ${StringUtils.capitalize(contacts[index].nom)}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${contacts[index].phone}'),
                      trailing: IconButton(
                          icon: Icon(
                            contacts[index].isFav
                                ? Icons.star
                                : Icons.star_border,
                            color: contacts[index].isFav
                                ? Color(0xFFF2B538)
                                : Color(0XFF1F1F30),
                          ),
                          onPressed: () {
                            // If there is network, the datas are saved or else an alert error is shown
                            http
                                .get(Uri.parse('http://10.0.2.2:8000/'))
                                .timeout(
                              const Duration(seconds: 1),
                              onTimeout: () {
                                // Time has run out, do what you wanted to do.
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                    title: const Text('Internet error 🌍'),
                                    content: const Text(
                                        'Vérifiez votre connexion internet'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'OK'),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                throw ("big error 404"); // Request Timeout response status code
                              },
                            ).whenComplete(() {
                              updateFav(
                                  contacts[index].id, contacts[index].isFav);

                              Navigator.of(context).pushNamed('/home');
                            });
                          }),
                    ))
                : Text("");
            //return Image.network(contacts[index].photo);
          },
        );
      }
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(lang == "fr" ? "Aucun favoris" : "Favorite's list is Empty",
              style: TextStyle(
                  color: _darkTheme ? Colors.white : null, fontSize: 18)),
          Icon(Icons.stars, size: 200, color: Color(0xFFF2B538)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                primary: _darkTheme ? Colors.white : Color(0XFF1F1F30),
                onPrimary: _darkTheme ? Color(0XFF1F1F30) : null),
            onPressed: () {
              Navigator.of(context).pushNamed('/home');
            },
            child: Text(lang == "fr" ? "Ajouter" : "Add",
                style: TextStyle(fontSize: 18)),
          ),
        ],
      );
    }
  }
}