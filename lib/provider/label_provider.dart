import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class LabelProvider {

  static int? selectedLabel;
  static List<String> labels = [
    'Male',
    'Female',
    'Pregnancy',
    'Pregnancy-Boy',
    'Pregnancy-Girl',
  ];

  static List<DropdownMenuItem<int>> getLabelDropdownList() {
    return labels.indexed.map((e) {
      return DropdownMenuItem(
        value: e.$1,
        child: SizedBox(
            child: Text(e.$2)
        )
      );
    }).toList();
  }


}