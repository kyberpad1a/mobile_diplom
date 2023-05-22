import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mobile_diplom/orderMap.dart';

class orders extends StatefulWidget {
  const orders({super.key, required this.iduser});
  static const routeName = "/orders";
  final int iduser;
  ///Инициализация окна состояния
  @override
  State<orders> createState() => _ordersState();
}

class _ordersState extends State<orders> {
  List data = [];
  ///Получение активных заказов
  Future<String> getData() async {
    var response = await http.get(
        Uri.parse("https://192.168.0.109:44317/api/getorders"),
        headers: {"Accept": "application/json"});

    setState(() {
      data = json.decode(response.body);
    });
    return "Success";
  }
  ///Изменение статуса занятости заказа
  Future<int> TakeOrders(int id) async {
    
    var map = new Map<String, dynamic>();
    map['idshipping'] = id;
    map['user_iduser'] = widget.iduser;
    var response = await http.put(
      Uri.parse("https://192.168.0.109:44317/api/updatetaken"),
        
        headers: {
          "accept": "application/json",
          "content-type": "application/json"
        },
        body: jsonEncode(map));

    return response.statusCode;
  }
  ///Инициализация состояния окна
  @override
  void initState() {
    super.initState();
    getData();
  }
  ///Сборка виджетов окна
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Заказы"),
      ),
      body: Center(
        child: getList(),
      ),
    );
  }
  ///Виджет ListView
  Widget getList() {
    if (data == null || data.length < 1) {
      return Container(
        child: Center(
          child: Text("Подождите..."),
        ),
      );
    }
    return ListView.separated(
      itemCount: data.length,
      itemBuilder: (BuildContext context, int index) {
        return getListItem(index);
      },
      separatorBuilder: (context, index) {
        return Divider();
      },
    );
  }
  ///Виджет, содержащий данные заказа
  Widget? getListItem(int i) {
    if (data == null || data.length < 1) return null;

    return InkWell(
      child: Container(
        child: Container(
          margin: EdgeInsets.all(6.0),
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              data[i]['shipping_address'].toString(),
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
      onTap: () async {
        int response = await TakeOrders(data[i]['idshipping']);
                setState(() {
          getData();
        });
        if (response == 204) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Заказ принят'),
          ));
          sleep(Duration(seconds: 2));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => orderMap(iduser: widget.iduser),
            ),
          );
        } else if (response == 404) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Заказ не найден'),
          ));
        } else if (response == 102){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Отсутствует соединение с сервером'),
          ));
        }
      },
    );
  }
}
