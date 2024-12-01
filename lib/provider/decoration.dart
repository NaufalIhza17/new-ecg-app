/*
 * Copyright (c) 2018-2022 Taner Sener
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'package:flutter/material.dart';

final appThemeData = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  useMaterial3: true,
);

final buttonDecoration = BoxDecoration(
    color: const Color.fromRGBO(46, 204, 113, 1.0),
    borderRadius: BorderRadius.circular(5),
    border: Border.all(color: const Color.fromRGBO(39, 174, 96, 1.0)));

final videoPlayerFrameDecoration = BoxDecoration(
  color: const Color.fromRGBO(236, 240, 241, 1.0),
  border: Border.all(color: const Color.fromRGBO(185, 195, 199, 1.0), width: 1.0),
);

final dropdownButtonDecoration = BoxDecoration(
    color: appThemeData.colorScheme.inversePrimary.withOpacity(0.8),
    borderRadius: BorderRadius.circular(5),
    border: Border.all(color: appThemeData.colorScheme.primary));

final outputDecoration = BoxDecoration(
    borderRadius: const BorderRadius.all(Radius.circular(5)),
    color: const Color.fromRGBO(241, 196, 15, 1.0),
    border: Border.all(color: const Color.fromRGBO(243, 156, 18, 1.0)));

const buttonTextStyle = TextStyle(
    fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white);

const buttonSmallTextStyle = TextStyle(
    fontSize: 10.0, fontWeight: FontWeight.bold, color: Colors.white);

final hintTextStyle = TextStyle(fontSize: 14, color: Colors.grey[400]);

const selectedTabColor = Color(0xFF1e90ff);
const unSelectedTabColor = Color(0xFF808080);

const tabBarDecoration = BoxDecoration(
  border: Border(
    top: BorderSide(
      color: unSelectedTabColor,
      width: 1.0,
    ),
    bottom: BorderSide(
      width: 0.0,
    ),
  ),
);

const textFieldStyle = TextStyle(fontSize: 14, color: Colors.black);

const dropdownButtonTextStyle = TextStyle(
  fontSize: 18,
  color: Colors.black,
);

InputDecoration inputDecoration(String hintText) {
  return InputDecoration(
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromRGBO(52, 152, 219, 1.0)),
        borderRadius: BorderRadius.all(
          Radius.circular(5),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromRGBO(52, 152, 219, 1.0)),
        borderRadius: BorderRadius.all(
          Radius.circular(5),
        ),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromRGBO(52, 152, 219, 1.0)),
        borderRadius: BorderRadius.all(
          Radius.circular(5),
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      hintStyle: hintTextStyle,
      hintText: hintText);
}
