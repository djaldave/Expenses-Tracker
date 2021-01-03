import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import "dart:convert";
import 'models/transaction.dart';
import 'widgets/chart.dart';
import 'widgets/new_transaction.dart';
import 'widgets/transaction_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Expenses Tracker",
      home: MyHomePage(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        accentColor: Colors.blue,
        errorColor: Colors.red,
        fontFamily: "Quicksand",
        textTheme: ThemeData.light().textTheme.copyWith(
              headline6: TextStyle(
                  fontFamily: "OpenSans",
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
              button: TextStyle(color: Colors.white),
            ),
        appBarTheme: AppBarTheme(
          textTheme: ThemeData.light().textTheme.copyWith(
                headline6: TextStyle(
                  fontFamily: "Quicksand",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Transaction> _userTransaction = [];
  bool isLoading = false;
  initState() {
    fetchPassList();
    super.initState();
  }

  List<Transaction> get _recentTransaction {
    return _userTransaction.where((tx) {
      return tx.date.isAfter(DateTime.now().subtract(Duration(days: 7)));
    }).toList();
  }

  void _addNewTransaction(String title, double amount, DateTime chosenDate) {
    isLoading = true;
    final Map<String, dynamic> transaction = {
      "title": title,
      "amount": amount,
      "date": chosenDate.toIso8601String()
    };
    http
        .post(
            "https://expenses-264d0-default-rtdb.firebaseio.com/transaction.json",
            body: json.encode(transaction))
        .then((http.Response response) {
      setState(() {
        fetchPassList();
        isLoading = false;
      });
    });
  }

  Future<void> fetchPassList() async {
    final List<Transaction> tempList = [];
    isLoading = true;
    http
        .get(
            "https://expenses-264d0-default-rtdb.firebaseio.com/transaction.json")
        .then((http.Response response) {
      final Map<String, dynamic> listData = json.decode(response.body);

      if (listData == null) {
        setState(() {
          isLoading = false;
          return;
        });
      } else {
        listData.forEach((conId, data) {
          isLoading = false;

          final Transaction pstlst = Transaction(
              id: conId,
              title: data['title'],
              amount: data['amount'],
              date: DateTime.parse(data['date']));

          tempList.add(pstlst);
        });

        setState(() {
          isLoading = false;
          _userTransaction = tempList;
        });
      }
    });
  }

  void _startAddNewTransaction(BuildContext ctx) {
    showModalBottomSheet(
        context: ctx,
        builder: (_) {
          return GestureDetector(
            child: NewTransaction(_addNewTransaction),
            behavior: HitTestBehavior.opaque,
            onTap: () {},
          );
        });
  }

  void _deleteTransaction(String id, int index) {
    http
        .delete(
            "https://expenses-264d0-default-rtdb.firebaseio.com/transaction/${_userTransaction[index].id}.json")
        .then((http.Response response) {
      setState(() {
        _userTransaction.removeWhere((tx) => tx.id == id);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Expenses Tracker",
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _startAddNewTransaction(context)),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Chart(_recentTransaction),
                  TransactionList(_userTransaction, _deleteTransaction),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _startAddNewTransaction(context),
      ),
    );
  }
}
