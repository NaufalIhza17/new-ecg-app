import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecg/components/svg_button.dart';
import 'package:ecg/components/text_button.dart';
import 'new_home.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildUI(context),
    );
  }

  Widget _buildUI(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF202020), Color(0xFF171717)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 50,
              ),
              _title(context),
              const SizedBox(
                height: 50,
              ),
              _authenticationBox(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ECG",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 64,
              height: 1.0,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: 150,
            child: Text(
              "Guide you to living your best life",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
                fontSize: 16,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _authenticationBox(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width - 40,
        decoration: BoxDecoration(
          color: const Color(0x1A6C6C6C),
          borderRadius: BorderRadius.circular(40),
        ),
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Get Started",
                  style:
                      TextStyle(fontSize: 20, color: Colors.white, height: 1.0),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  "We’re excited to have you on board! Please choose a way to sign up or log in",
                  style: TextStyle(
                    color: Color(0xFF939393),
                    fontSize: 14,
                    height: 1.0,
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                CustomTextButton(
                  text: "Continue with phone",
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyHomePage(
                                  title: "ECG",
                                )));
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                CustomTextButton(
                  text: "Continue with email",
                  onPressed: () {},
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    CustomSvgButton(
                      svgAsset: 'assets/icons/google.svg',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              child: Container(
                                width: 300,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF202020),
                                  borderRadius: BorderRadius.circular(
                                    20,
                                  ),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Notice',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'This method is not available yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Close the dialog
                                        },
                                        child: const Text(
                                          'OK',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      buttonWidth: 140,
                      svgWidth: 20,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    CustomSvgButton(
                      svgAsset: 'assets/icons/apple.svg',
                      onPressed: () {},
                      buttonWidth: 140,
                      svgWidth: 28,
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
