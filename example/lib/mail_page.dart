import 'package:example/detailscreen.dart';
import 'package:example/helper.dart';
import 'package:flutter/material.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

import 'mail_model.dart';
import 'widget/mail_tile.dart';

class MailPage extends StatefulWidget {
  const MailPage({Key? key}) : super(key: key);

  @override
  _MailPageState createState() => _MailPageState();
}

class _MailPageState extends State<MailPage> {
  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();
  final GlobalKey firstMutliWidgetKey = GlobalKey();
  final GlobalKey secondMutliWidgetKey = GlobalKey();
  final GlobalKey thirdMutliWidgetKey = GlobalKey();

  List<Mail> mails = [];

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    //Start showcase view after current widget frames are drawn.
    //NOTE: remove ambiguate function if you are using
    //flutter version greater than 3.x and direct use WidgetsBinding.instance
    ambiguate(WidgetsBinding.instance)?.addPostFrameCallback(
      (_) => ShowCaseWidget.of(context)
          .startShowCase([_one, _two, firstMutliWidgetKey]),
    );
    mails = [
      Mail(
        sender: 'Medium',
        sub: 'Showcase View',
        msg: 'Check new showcase View',
        date: '1 May',
        isUnread: false,
      ),
      Mail(
        sender: 'Quora',
        sub: 'New Question for you',
        msg: 'Hi, There is new question for you',
        date: '2 May',
        isUnread: true,
      ),
      Mail(
        sender: 'Google',
        sub: 'Flutter 1.5',
        msg: 'We have launched Flutter 1.5',
        date: '3 May',
        isUnread: false,
      ),
      Mail(
        sender: 'Github',
        sub: 'Showcase View',
        msg: 'New star on your showcase view.',
        date: '4 May ',
        isUnread: true,
      ),
      Mail(
        sender: 'Simform',
        sub: 'Credit card Plugin',
        msg: 'Check out our credit card plugin',
        date: '5 May',
        isUnread: false,
      ),
      Mail(
        sender: 'Flutter',
        sub: 'Flutter is Future',
        msg: 'Flutter launched for Web',
        date: '6 May',
        isUnread: true,
      ),
      Mail(
        sender: 'Medium',
        sub: 'Showcase View',
        msg: 'Check new showcase View',
        date: '7 May ',
        isUnread: false,
      ),
      Mail(
        sender: 'Simform',
        sub: 'Credit card Plugin',
        msg: 'Check out our credit card plugin',
        date: '8 May',
        isUnread: true,
      ),
      Mail(
        sender: 'Flutter',
        sub: 'Flutter is Future',
        msg: 'Flutter launched for Web',
        date: '9 May',
        isUnread: false,
      ),
    ];
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: 10, right: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffcaf0f8),
                            border: Border.all(
                              color: const Color(0xffcaf0f8),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Showcase(
                                      key: _one,
                                      description: 'Tap to see menu options',
                                      disableDefaultTargetGestures: true,
                                      child: GestureDetector(
                                        onTap: () =>
                                            debugPrint('menu button clicked'),
                                        child: Icon(
                                          Icons.menu,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      actions: ShowCaseDefaultActions(
                                        previous: ActionButtonConfig(
                                          icon: Image.asset(
                                            'assets/left.png',
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          buttonTextVisible: false,
                                        ),
                                        next: ActionButtonConfig(
                                          icon: Image.asset(
                                            'assets/right.png',
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          textDirection: TextDirection.rtl,
                                          buttonTextVisible: false,
                                        ),
                                        stop: ActionButtonConfig(
                                          icon: Image.asset(
                                            'assets/close.png',
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          buttonTextVisible: false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    const Text(
                                      'Search email',
                                      style: TextStyle(
                                        color: Colors.black45,
                                        fontSize: 16,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.search,
                                      color: Color(0xffcaf0f8),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Showcase(
                      targetPadding: const EdgeInsets.all(5),
                      key: _two,
                      title: 'Profile',
                      description:
                          "Tap to see profile which contains user's name, profile picture, mobile number and country",
                      tooltipBackgroundColor: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                      targetShapeBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset('assets/simform.png'),
                      ),
                      actions: ShowCaseDefaultActions(
                        previous: ActionButtonConfig(
                          icon: Image.asset(
                            'assets/left.png',
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        next: ActionButtonConfig(
                          icon: Image.asset(
                            'assets/right.png',
                            color: Theme.of(context).primaryColor,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        stop: ActionButtonConfig(
                          icon: Image.asset(
                            'assets/close.png',
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        dividerThickness: 0.0,
                        verticalDividerColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: const Text(
                    'PRIMARY',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.only(top: 8)),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return showcaseMailTile(
                      firstMutliWidgetKey,
                      [secondMutliWidgetKey, thirdMutliWidgetKey],
                      false,
                      context,
                      mails[index],
                    );
                  }
                  return MailTile(
                    key: index == 2 ? secondMutliWidgetKey : null,
                    mail: mails[index % mails.length],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: MultiView(
        key: thirdMutliWidgetKey,
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () {
            setState(() {
              /* reset ListView to ensure that the showcased widgets are
               * currently rendered so the showcased keys are available in the
               * render tree. */
              scrollController.jumpTo(0);
            });
          },
          child: const Icon(
            Icons.add,
          ),
        ),
      ),
    );
  }

  GestureDetector showcaseMailTile(
    GlobalKey showCaseKey,
    List<GlobalKey<State<StatefulWidget>>> keys,
    bool showCaseDetail,
    BuildContext context,
    Mail mail,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const Detail(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Showcase(
          key: showCaseKey,
          keys: keys,
          description: 'Tap to check mail',
          tooltipPosition: TooltipPosition.top,
          disposeOnTap: true,
          onTargetClick: () {},
          child: MailTile(
            mail: mail,
            showCaseDetail: showCaseDetail,
          ),
          actions: ShowCaseDefaultActions(
            previous: ActionButtonConfig(
              icon: Image.asset(
                'assets/left.png',
                color: Theme.of(context).primaryColor,
              ),
            ),
            next: ActionButtonConfig(
              icon: Image.asset(
                'assets/right.png',
                color: Theme.of(context).primaryColor,
              ),
              textDirection: TextDirection.rtl,
            ),
            stop: ActionButtonConfig(
              icon: Image.asset(
                'assets/close.png',
                color: Theme.of(context).primaryColor,
              ),
            ),
            dividerThickness: 0.0,
            verticalDividerColor: Colors.transparent,
          ),
          actionButtonsPosition: const ActionButtonsPosition(),
        ),
      ),
    );
  }
}
