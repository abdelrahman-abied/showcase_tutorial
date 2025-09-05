class Mail {
  Mail({
    required this.sender,
    required this.sub,
    required this.msg,
    required this.date,
    required this.isUnread,
    this.isImportant = false,
  });

  String sender;
  String sub;
  String msg;
  String date;
  bool isUnread;
  bool isImportant;
}
