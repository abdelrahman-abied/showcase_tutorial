import 'package:example/widget/skip_tool_tip.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../mail_model.dart';
import 'sample_avatar_widget.dart';

class MailTile extends StatelessWidget {
  final Key? twoWidgetKey;

  const MailTile({
    required this.mail,
    this.showCaseDetail = false,
    this.showCaseKey,
    this.twoWidgetKey,
  });
  final bool showCaseDetail;
  final GlobalKey<State<StatefulWidget>>? showCaseKey;
  final Mail mail;

  @override
  Widget build(BuildContext context) {
    debugPrint('index: ${twoWidgetKey.toString()}');
    return MultiView(
      child: Container(
        padding: const EdgeInsets.only(left: 6, right: 16, top: 8, bottom: 8),
        color: mail.isUnread ? const Color(0xffFFF6F7) : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (showCaseDetail) ...[
                    Showcase.withWidget(
                      key: showCaseKey!,
                      overlayColor: Colors.black12,
                      height: 150,
                      width: 140,
                      targetShapeBorder: const CircleBorder(),
                      targetBorderRadius: const BorderRadius.all(
                        Radius.circular(150),
                      ),
                      container: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                            child: Column(children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xffFCD8DC),
                                ),
                                child: Center(
                                  child: Text(
                                    'S',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              ShipToolTip(parentContext: context),
                            ]),
                          ),
                        ],
                      ),
                      child: const SAvatarExampleChild(),
                      actionButtonsPosition: const ActionButtonsPosition(),
                    )
                  ] else
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
                    mail.isUnread ? Icons.star : Icons.star_border,
                    color: mail.isUnread ? const Color(0xffFBC800) : Colors.grey,
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
