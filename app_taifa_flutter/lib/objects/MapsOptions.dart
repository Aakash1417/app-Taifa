enum Options { addPin, addClient, switchView }

extension OptionExtension on Options {
  String get stringValue {
    switch (this) {
      case Options.addPin:
        return 'Add Pin';
      case Options.addClient:
        return 'Add Client';
      case Options.switchView:
        return 'Switch View';
    }
  }
}
