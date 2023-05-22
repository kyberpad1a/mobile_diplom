import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:mobile_diplom/orderMap.dart';
import 'dart:io';

import 'package:mobile_diplom/orders.dart';
///Сборка приложения
void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const routeName = '/signin';
///Задание параметров приложения
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiplomMobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Страница авторизации'),

    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  ///Инициализация состояния окна
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class MyHttpOverrides extends HttpOverrides {
  ///Сборка HTTP-клиента и инициализация сертификатов безопасности
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  int id = 0;
  List data = [];
  ///Метод обращения к API для осуществления авторизации
  Future<bool> authRequest(String username, String password) async {
    var map = new Map<String, dynamic>();

    map['username'] = username;

    map['password'] = BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 8));
    var response = await http.post(
        Uri.parse('https://192.168.0.109:44317/api/auth'),
        headers: {
          "accept": "application/json",
          "content-type": "application/json"
        },
        body: jsonEncode(map));
    List dbpwd = jsonDecode(response.body);
    String pwdForCompare = dbpwd[0]['password'];
    id = dbpwd[0]['iduser'];
    final isValidPassword = await BCrypt.checkpw(password, pwdForCompare);

    return isValidPassword;
  }
  ///Метод получения активных заказов пользователя
  Future<String> getOrderData() async {
    var map = new Map<String, dynamic>();

    map['user_iduser'] = id;
    var response = await http.post(
        Uri.parse("https://192.168.0.109:44317/api/getorderdata"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json"
        },
        body: json.encode(map));
    setState(() {
      data = json.decode(response.body);
      print(data);
    });
    
    return "Success";
  }
  ///Сборка виджетов текущего окна
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторизация'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _loginController,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Введите логин';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Логин',
                ),
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Введите пароль';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    bool flag = await authRequest(
                        _loginController.text, _passwordController.text);
                    if (flag == true) {
                      setState(() {
                        getOrderData();
                      });
                      
                      print(data);
                      if (data.isEmpty == true) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => orders(iduser: id),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => orderMap(iduser: id),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Неверное имя пользователя или пароль'),
                      ));
                    }
                  }
                },
                child: const Text('Войти'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
