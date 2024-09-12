import 'package:flutter/material.dart';
import 'package:validators/validators.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Ensures that plugin binding is initialized
  // Get application directory for Hive
  final appDocumentDir = await getApplicationDocumentsDirectory(); 
  Hive.init(appDocumentDir.path);  // Initialize Hive with the correct path

  await Hive.openBox('calculations');  // Open a box to store your data
  runApp(const MyApp());
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double output = 50;
  double percentage = 0;
  double input = 0;
  String selectedParam = '-';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();  // Load history from Hive
  }

  void calculate() {
    setState(() {
      switch (selectedParam) {
        case '-':
          output = double.parse((input - ((input * percentage) / 100)).toStringAsFixed(3));
          break;
        case '+':
          output = double.parse((input + ((input * percentage) / 100)).toStringAsFixed(3));
          break;
        case '/':
          output = double.parse((input / ((input * percentage) / 100)).toStringAsFixed(3));
          break;
        case 'X':
          output = double.parse((input * ((input * percentage) / 100)).toStringAsFixed(3));
          break;
      }
    });
  }
  void saveToHistory() async {
    var box = Hive.box('calculations');
    dynamic newEntry = {
      'id': DateTime.now().millisecondsSinceEpoch,  // Unique ID based on timestamp
      'input': input,
      'percentage': percentage,
      'output': output,
      'selectedParam': selectedParam
    };
    box.add(newEntry);  // Save to Hive

    // Update local history
    setState(() {
      history.add(newEntry);
    });
  }
  Future<void> loadHistory() async {
    var box = Hive.box('calculations');
    setState(() {
      history = box.values.cast<dynamic>().toList();
    });
  }
  void deleteById(int id) async {
    var box = Hive.box('calculations');
    
    // Find the index of the item with the matching 'id'
    final int index = history.indexWhere((entry) => entry['id'] == id);

    if (index != -1) {
      await box.deleteAt(index);  // Delete the entry from the Hive box

      // Update local history by removing the item
      setState(() {
        history.removeAt(index);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    void setValues(String type,String value){
      if((isInt(value) || isFloat(value)) && value != ''){
        switch (type) {
          case 'input':
            input = double.parse(value);
            calculate();
            break;
          case 'percentage':
            percentage = double.parse(value);
            calculate();
            break;
        }
      }
    }
    void changeMethod(String type){
      setState(() {
        switch (type) {
          case 'subtract':
            selectedParam = '-';
            break;
          case 'addition':
            selectedParam = '+';
            break;
          case 'multiplication':
            selectedParam = 'X';
            break;
          case 'division':
            selectedParam = '/';
            break;
        }
        calculate();
      });
    }
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xff111214),
        endDrawer: Drawer(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(0)),
          ),
          child: Container(
            color:const Color(0xff232428),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final historyItem = history[index];
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 15, bottom: 15),
                      color: const Color(0xff232428),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            historyItem['input'].toString(),
                            style: const TextStyle(fontSize: 24, color: Colors.white),
                          ),
                          Text(
                            historyItem['selectedParam'],
                            style:const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            historyItem['percentage'].toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            '%',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            '=',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            historyItem['output'].toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(onPressed: (){deleteById(historyItem['id']);}, icon:const Icon(Icons.delete,color: Color(0xff4e4c53),size: 20,),),
                        ],
                      ),
                    ),
                    const Divider(
                      color: Colors.white,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: 300,
                decoration: const BoxDecoration(
                  color: Color(0xff232428),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 100,
                            child: Center(
                              child: TextFormField(
                                onChanged: (value) => {
                                  setValues('input', value)
                                },
                                decoration: const InputDecoration(
                                  hintText: '1000',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 48, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 125,
                            height: 125,
                            child: Column(
                              children: [
                                Buttons(
                                  changeMethod: (value) {
                                    changeMethod(value);
                                  },
                                ),
                                SizedBox(
                                  height: 80,
                                  child: Text(
                                    selectedParam,
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                        fontSize: 64,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 150,
                                height: 100,
                                child: Center(
                                  child: TextFormField(
                                    onChanged: (value) => {
                                      setValues('percentage', value)
                                    },
                                    decoration: const InputDecoration(
                                      hintText: '5',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 64,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const Text(
                                '%',
                                style: TextStyle(
                                    fontSize: 64, color: Colors.white),
                              ),
                            ],
                          ),
                          const Text(
                            '=',
                            style: TextStyle(
                                fontSize: 72,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$output',
                            style: const TextStyle(
                                fontSize: 72,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 60,
                      ),
                      TextButton(
                        onPressed: () {
                          // Your action here
                          saveToHistory();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 10, bottom: 10), // Removes padding
                          minimumSize: const Size(35, 35), // Set the minimum size of the button
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero, // No border radius
                            side: BorderSide(color: Color(0xff4e4c53), width: 1),
                          ),
                        ),
                        child: const Text(
                          'Save to History',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xff4e4c53), // Adjust font size
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          shape:const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // No border radius
          ),
          backgroundColor:const Color(0xff232428),
          child:const Icon(Icons.menu,color: Color(0xff4e4c53),),
        ),
      ),
    );
  }
}

class Buttons extends StatelessWidget {
  const Buttons({
    super.key,
    required this.changeMethod
  });
  final Function(String value) changeMethod;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              // Your action here
              changeMethod('division');
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero, // Removes padding
              minimumSize:const Size(35,35), // Set the minimum size of the button
              shape:const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // No border radius
                side: BorderSide(
                  color: Color(0xff4e4c53),
                  width: 1
                )
              ),
            ),
            child:const Text(
              '/',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xff4e4c53) // Adjust font size
              ),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            onPressed: () {
              // Your action here
              changeMethod('multiplication');
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero, // Removes padding
              minimumSize:const Size(35,35), // Set the minimum size of the button
              shape:const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // No border radius
                side: BorderSide(
                  color: Color(0xff4e4c53),
                  width: 1
                )
              ),
            ),
            child:const Text(
              'X',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xff4e4c53) // Adjust font size
              ),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            onPressed: () {
              // Your action here
              changeMethod('addition');
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero, // Removes padding
              minimumSize:const Size(35,35), // Set the minimum size of the button
              shape:const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // No border radius
                side: BorderSide(
                  color: Color(0xff4e4c53),
                  width: 1
                )
              ),
            ),
            child:const Text(
              '+',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xff4e4c53) // Adjust font size
              ),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            onPressed: () {
              // Your action here
              changeMethod('subtract');
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero, // Removes padding
              minimumSize:const Size(35,35), // Set the minimum size of the button
              shape:const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // No border radius
                side: BorderSide(
                  color: Color(0xff4e4c53),
                  width: 1
                )
              ),
            ),
            child:const Text(
              '-',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xff4e4c53) // Adjust font size
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}