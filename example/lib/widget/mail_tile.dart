import 'package:flutter/material.dart';

import '../mail_model.dart';
import 'sample_avatar_widget.dart';

class MailTile extends StatelessWidget {
  const MailTile({
    Key? key,
    required this.mail,
    this.showCaseDetail = false,
    this.showCaseKey,
  }) : super(key: key);
  final bool showCaseDetail;
  final GlobalKey<State<StatefulWidget>>? showCaseKey;
  final Mail mail;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.only(left: 6, right: 16, top: 8, bottom: 8),
        color: mail.isUnread ? const Color(0xffcaf0f8) : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SAvatarExampleChild(),
                  const Padding(padding: EdgeInsets.only(left: 8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          mail.sender,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: mail.isUnread ? FontWeight.bold : FontWeight.normal,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          mail.sub,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          mail.msg,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: mail.isUnread ? Theme.of(context).primaryColor : Colors.black,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              width: 50,
              child: Column(
                children: <Widget>[
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    mail.date,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Icon(
                    mail.isImportant ? Icons.star : Icons.star_border,
                    color: mail.isImportant ? Colors.blue : Color(0xffFFFFFF),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
