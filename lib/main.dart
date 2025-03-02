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
  bool isReverseMode = false; // State variable for toggling calculation mode
  
  // Added variables to store values when switching modes
  double normalModeInput = 0;
  double normalModeOutput = 50;
  double reverseModeInput = 0;
  double reverseModeOutput = 0;
  
  // Controllers for text fields
  final TextEditingController inputController = TextEditingController();
  final TextEditingController outputController = TextEditingController(); // New controller for output field in reverse mode
  final TextEditingController percentageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadHistory();  // Load history from Hive
    inputController.text = input.toString();
    outputController.text = output.toString();
  }

  void calculate() {
    setState(() {
      if (!isReverseMode) {
        // Normal calculation (x operation percentage% = result)
        switch (selectedParam) {
          case '-':
            output = double.parse((input - ((input * percentage) / 100)).toStringAsFixed(3));
            break;
          case '+':
            output = double.parse((input + ((input * percentage) / 100)).toStringAsFixed(3));
            break;
          case '/':
            if (percentage == 0) {
              output = 0; // Avoid division by zero
            } else {
              output = double.parse((input / ((percentage / 100))).toStringAsFixed(3));
            }
            break;
          case 'X':
            output = double.parse((input * (percentage / 100)).toStringAsFixed(3));
            break;
        }
        
        // Store values for mode switching
        normalModeInput = input;
        normalModeOutput = output;
      } else {
        // Reverse calculation (find original value from result and percentage)
        try {
          switch (selectedParam) {
            case '-':
              // If result = original - (original * percentage/100)
              // Then result = original * (1 - percentage/100)
              // So original = result / (1 - percentage/100)
              double fraction = 1 - (percentage / 100);
              if (fraction == 0) {
                input = 0; // Handle division by zero
              } else {
                input = double.parse((output / fraction).toStringAsFixed(3));
              }
              break;
            case '+':
              // If result = original + (original * percentage/100)
              // Then result = original * (1 + percentage/100)
              // So original = result / (1 + percentage/100)
              double fraction = 1 + (percentage / 100);
              input = double.parse((output / fraction).toStringAsFixed(3));
              break;
            case '/':
              // Reverse of division calculation
              if (percentage == 0) {
                input = 0; // Handle division by zero
              } else {
                input = double.parse((output * (percentage / 100)).toStringAsFixed(3));
              }
              break;
            case 'X':
              // Reverse of multiplication calculation
              if (percentage == 0) {
                input = 0; // Handle division by zero
              } else {
                input = double.parse((output / (percentage / 100)).toStringAsFixed(3));
              }
              break;
          }
        } catch (e) {
          // Handle errors, such as division by zero
          input = 0;
        }
        
        // Store values for mode switching
        reverseModeInput = input;
        reverseModeOutput = output;
        
        // Update input controller to reflect the new calculated value
        inputController.text = input.toString();
      }
    });
  }

  // Function to handle mode switching and value swapping
  void toggleCalculationMode(bool newMode) {
  if (newMode != isReverseMode) {
    setState(() {
      isReverseMode = newMode;
      
      if (isReverseMode) {
        // Switching to reverse mode
        // Save current normal mode values
        normalModeInput = input;
        normalModeOutput = output;
        
        // In reverse mode, start fresh with empty/zero values
        input = 0;
        output = 0;
        inputController.text = "0"; // Reset to zero instead of using normal mode output
        outputController.text = "0";
      } else {
        // Switching to normal mode
        // Save current reverse mode values
        reverseModeInput = input;
        reverseModeOutput = output;
        
        // Restore normal mode values
        // input = normalModeInput;
        // output = normalModeOutput;
        input = 0;
        output = 0;
        inputController.text = "0";
        outputController.text = "0";
        // inputController.text = normalModeInput.toString();
        // outputController.text = normalModeOutput.toString();
      }
    });
  }
}

  void saveToHistory() async {
    var box = Hive.box('calculations');
    dynamic newEntry = {
      'id': DateTime.now().millisecondsSinceEpoch,  // Unique ID based on timestamp
      'input': isReverseMode ? output : input, // In reverse mode, output is the "input" value
      'percentage': percentage,
      'output': isReverseMode ? input : output, // In reverse mode, input is the "output" value
      'selectedParam': selectedParam,
      'isReverseMode': isReverseMode // Save the calculation mode
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
  void dispose() {
    // Clean up controllers when the widget is disposed
    inputController.dispose();
    outputController.dispose();
    percentageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    void setValues(String type, String value) {
      if ((isInt(value) || isFloat(value)) && value != '') {
        switch (type) {
          case 'input':
            setState(() {
              input = double.parse(value);
              calculate();
            });
            break;
          case 'output':
            setState(() {
              if (isReverseMode) {
                output = double.parse(value);
                calculate();
              }
            });
            break;
          case 'percentage':
            setState(() {
              percentage = double.parse(value);
              calculate();
            });
            break;
        }
      }
    }
    
    void changeMethod(String type) {
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
                height: 350,
                decoration: const BoxDecoration(
                  color: Color(0xff232428),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 1),
                      // Toggle switch section remains the same
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Normal Mode',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 10,),
                          Switch(
                            value: isReverseMode,
                            onChanged: (value) {
                              toggleCalculationMode(value);
                            },
                            activeColor: const Color(0xff4e4c53),
                            activeTrackColor: const Color.fromARGB(59, 110, 110, 110),
                            inactiveTrackColor: Colors.black12,
                          ),
                          const SizedBox(width: 10,),
                          const Text(
                            'Reverse Mode',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // First column: Input in normal mode, Result Value in reverse mode
                          isReverseMode ? SizedBox(
                            child: Center(
                              child: Column(
                                  children: [
                                    Text(
                                      input.toString(),
                                      style: const TextStyle(
                                          fontSize: 72,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      'Result Value',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white54),
                                    ),
                                  ],
                                )
                                // In normal mode, show the input field
                            ),
                          ) :
                          SizedBox(
                            width: 150,
                            child: Center(
                              child: TextFormField(
                                    controller: inputController,
                                    onChanged: (value) => {
                                      setValues('input', value)
                                    },
                                    decoration: const InputDecoration(
                                      hintText: '1000',
                                      hintStyle: TextStyle(color: Colors.white38),
                                      labelText: 'Input',
                                      labelStyle: TextStyle(color: Colors.white70),
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 48, color: Colors.white),
                                  ),
                            ),
                          ),
                          // Operation buttons section - no changes needed
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
                          // Percentage section - no changes needed
                          Row(
                            children: [
                              SizedBox(
                                width: 150,
                                height: 100,
                                child: Center(
                                  child: TextFormField(
                                    controller: percentageController,
                                    onChanged: (value) => {
                                      setValues('percentage', value)
                                    },
                                    decoration: const InputDecoration(
                                      hintText: '5',
                                      hintStyle: TextStyle(color: Colors.white38),
                                      labelText: 'Percentage',
                                      labelStyle: TextStyle(color: Colors.white70),
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
                          // Last column: Result in normal mode, Input field in reverse mode
                          isReverseMode ? SizedBox(
                            width: 150,
                            child: TextFormField(
                                  controller: outputController,
                                  onChanged: (value) => {
                                    setValues('output', value)
                                  },
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: Colors.white38),
                                    labelText: 'Input',
                                    labelStyle: TextStyle(color: Colors.white70),
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 48, color: Colors.white),
                                )
                              // In normal mode, show the result as text
                          ) :
                          SizedBox(
                            child: Column(
                                  children: [
                                    Text(
                                      output.toString(),
                                      style: const TextStyle(
                                          fontSize: 72,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      'Result',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white54),
                                    ),
                                  ],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      // Save button section - no changes needed
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              saveToHistory();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(
                                  left: 20, right: 20, top: 10, bottom: 10),
                              minimumSize: const Size(35, 35),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                                side: BorderSide(color: Color(0xff4e4c53), width: 1),
                              ),
                            ),
                            child: const Text(
                              'Save to History',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xff4e4c53),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
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
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          backgroundColor: const Color(0xff232428),
          child: const Icon(Icons.menu, color: Color(0xff4e4c53)),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // TextButton(
          //   onPressed: () {
          //     // Your action here
          //     changeMethod('division');
          //   },
          //   style: TextButton.styleFrom(
          //     padding: EdgeInsets.zero, // Removes padding
          //     minimumSize: const Size(35,35), // Set the minimum size of the button
          //     shape: const RoundedRectangleBorder(
          //       borderRadius: BorderRadius.zero, // No border radius
          //       side: BorderSide(
          //         color: Color(0xff4e4c53),
          //         width: 1
          //       )
          //     ),
          //   ),
          //   child: const Text(
          //     '/',
          //     style: TextStyle(
          //       fontSize: 18,
          //       color: Color(0xff4e4c53) // Adjust font size
          //     ),
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          // TextButton(
          //   onPressed: () {
          //     // Your action here
          //     changeMethod('multiplication');
          //   },
          //   style: TextButton.styleFrom(
          //     padding: EdgeInsets.zero, // Removes padding
          //     minimumSize: const Size(35,35), // Set the minimum size of the button
          //     shape: const RoundedRectangleBorder(
          //       borderRadius: BorderRadius.zero, // No border radius
          //       side: BorderSide(
          //         color: Color(0xff4e4c53),
          //         width: 1
          //       )
          //     ),
          //   ),
          //   child: const Text(
          //     'X',
          //     style: TextStyle(
          //       fontSize: 18,
          //       color: Color(0xff4e4c53) // Adjust font size
          //     ),
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          TextButton(
            onPressed: () {
              // Your action here
              changeMethod('addition');
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero, // Removes padding
              minimumSize: const Size(35,35), // Set the minimum size of the button
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // No border radius
                side: BorderSide(
                  color: Color(0xff4e4c53),
                  width: 1
                )
              ),
            ),
            child: const Text(
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
              minimumSize: const Size(35,35), // Set the minimum size of the button
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // No border radius
                side: BorderSide(
                  color: Color(0xff4e4c53),
                  width: 1
                )
              ),
            ),
            child: const Text(
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