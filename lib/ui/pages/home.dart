import 'dart:math';

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:unipi_orario/entities/lesson.dart';
import 'package:unipi_orario/helper/object_box.dart';
import 'package:unipi_orario/services/internal_api.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:unipi_orario/services/widget_handler.dart';
import 'package:unipi_orario/services/wrapper_impl.dart';
import 'package:unipi_orario/ui/components/home/event.dart';
import 'package:unipi_orario/utils/globals.dart' as globals;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GlobalKey timeLineKey = GlobalKey();

  InternalAPI internalAPI = Get.find<InternalAPI>();
  ObjectBox objectBox = Get.find<ObjectBox>();

  final EasyInfiniteDateTimelineController _controller = EasyInfiniteDateTimelineController();
  DateTime currentDate = DateTime.now();

  late PageController _pageController;
  int currentPageValue = 10000;

  late Future<List<String>> futureWithCourses;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentPageValue);
    futureWithCourses = getAllCourses();
  }

  Future<void> refreshData() async {
    setState(() {
      refreshing = true;
    });

    await refreshCaches();
    futureWithCourses = getAllCourses();

    setState(() {
      refreshing = false;
    });
  }

  Widget refreshButton() {
    Widget changeCalendarDialog() {
      String currentText = internalAPI.calendarId;

      return AlertDialog(
        title: Text(
          FlutterI18n.translate(
            context,
            "refreshDialog.title",
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: TextField(
                controller: TextEditingController(text: internalAPI.calendarId),
                onChanged: (value) {
                  currentText = value;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              subtitle: Text(
                FlutterI18n.translate(
                  context,
                  "refreshDialog.subtitle",
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (globals.calendarId != internalAPI.calendarId)
            TextButton(
              onPressed: () {
                internalAPI.calendarId = globals.calendarId;
                internalAPI.filteringCourses = [];
                Get.back();
              },
              child: Text(
                FlutterI18n.translate(
                  context,
                  "refreshDialog.reset",
                ),
              ),
            ),
          TextButton(
            onPressed: () {
              internalAPI.calendarId = currentText;
              internalAPI.filteringCourses = [];
              Get.back();
            },
            child: Text(
              FlutterI18n.translate(
                context,
                "refreshDialog.confirm",
              ),
            ),
          ),
          FilledButton.tonal(
            onPressed: () {
              Get.back();
            },
            child: Text(
              FlutterI18n.translate(
                context,
                "refreshDialog.cancel",
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: refreshData,
      onLongPress: () => Get.dialog(changeCalendarDialog()),
      borderRadius: BorderRadius.circular(30),
      child: const Icon(Icons.refresh),
    );
  }

  PreferredSizeWidget appBar() {
    return AppBar(
      leading: refreshButton(),
      actions: [
        ThemeSwitcher(
          builder: (ctx) => InkWell(
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: const Offset(0.0, 0.0),
                  ).animate(anim);

                  final bounceAnimation = Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(anim);

                  final fadeAnimation = Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(anim);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: ScaleTransition(
                      scale: bounceAnimation,
                      child: FadeTransition(
                        opacity: fadeAnimation,
                        child: child,
                      ),
                    ),
                  );
                },
                child: !internalAPI.isDarkMode
                    ? const Icon(
                        Icons.dark_mode,
                        key: ValueKey('dark'), // <-- senza key nva
                      )
                    : const Icon(
                        Icons.light_mode,
                        key: ValueKey('light'),
                      ),
              ),
              onPressed: () {
                internalAPI.setDarkMode(!internalAPI.isDarkMode, ctx);
              },
            ),
            onLongPress: () {
              internalAPI.setDynamicMode(!internalAPI.isDynamicTheme, ctx);
            },
          ),
        ),
      ],
    );
  }

  Widget timeLine() {
    TextStyle subStyle = TextStyle(
      fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
      color: Theme.of(context).disabledColor,
      fontWeight: FontWeight.w600,
    );

    DayStyle dayStyle = DayStyle(
      monthStrStyle: subStyle,
      dayStrStyle: subStyle,
      dayNumStyle: TextStyle(
        fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
    );

    List<String> months = [
      FlutterI18n.translate(context, "months.january"),
      FlutterI18n.translate(context, "months.february"),
      FlutterI18n.translate(context, "months.march"),
      FlutterI18n.translate(context, "months.april"),
      FlutterI18n.translate(context, "months.may"),
      FlutterI18n.translate(context, "months.june"),
      FlutterI18n.translate(context, "months.july"),
      FlutterI18n.translate(context, "months.august"),
      FlutterI18n.translate(context, "months.september"),
      FlutterI18n.translate(context, "months.october"),
      FlutterI18n.translate(context, "months.november"),
      FlutterI18n.translate(context, "months.december"),
    ];

    return EasyInfiniteDateTimeLine(
      key: timeLineKey,
      controller: _controller,
      //
      firstDate: DateTime(DateTime.september),
      lastDate: DateTime(DateTime.now().year).add(const Duration(days: 365 * 4)),
      focusDate: currentDate,
      //
      onDateChange: (selectedDate) {
        setState(() {
          currentDate = selectedDate;

          // TODO: refactor this in a way that actually makes sense.
          int toJump = currentPageValue + currentDate.difference(DateTime.now()).inDays;
          if (currentDate.isAfter(DateTime.now())) toJump++;
          _pageController.jumpToPage(toJump);
        });
      },
      activeColor: Theme.of(context).colorScheme.primaryContainer,
      locale: Localizations.localeOf(context).toLanguageTag(),
      dayProps: EasyDayProps(
        todayHighlightStyle: TodayHighlightStyle.withBackground,
        todayHighlightColor: Theme.of(context).colorScheme.tertiaryContainer,
        //
        activeDayStyle: dayStyle,
        todayStyle: dayStyle,
        inactiveDayStyle: dayStyle,
        //
        height: 80,
      ),
      headerBuilder: (context, date) {
        DateTime now = DateTime.now();
        bool isToday = now.day == currentDate.day && now.month == currentDate.month && now.year == currentDate.year;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          child: Row(
            children: [
              Text(
                "${months[currentDate.month - 1]} ${currentDate.year}",
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!isToday)
                SizedBox(
                  height: 30,
                  child: IconButton(
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _controller.animateToCurrentData();

                      setState(() {
                        currentDate = DateTime.now();
                      });

                      // TODO: refactor this too in a way that actually makes sense.
                      int toJump = currentPageValue + currentDate.difference(DateTime.now()).inDays;
                      if (currentDate.isAfter(DateTime.now())) toJump++;
                      _pageController.jumpToPage(toJump);
                    },
                    icon: const Icon(Icons.restore),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Widget eventsList() {
    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index - currentPageValue));

          return FutureBuilder(
            future: getLessonsForDay(date),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || refreshing) {
                Lesson fakeLesson = Lesson(
                  courseName: "Corso b",
                  endDateTime: DateTime.now(),
                  startDateTime: DateTime.now(),
                  name: "Neanche",
                  roomName: "D2",
                );
                List<Lesson> lessons = [for (int i = 0; i < 2; i++) fakeLesson];

                return Skeletonizer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: ListView.builder(
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        return Event(
                          lesson: lessons[index],
                        );
                      },
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    snapshot.error.toString(),
                  ),
                );
              }

              List<Lesson?> lessons = snapshot.data ?? [];

              if (lessons.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        globals.randomFaces[Random().nextInt(globals.randomFaces.length)],
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      const SizedBox(height: 10),
                      I18nText(
                        'home.noEvents',
                        child: Text(
                          "",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              lessons = lessons.where((element) {
                return element != null && !internalAPI.filteringCourses.contains(element.courseName ?? element.name);
              }).toList();
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: ListView.builder(
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    return Event(
                      lesson: lessons[index]!,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget filterList() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
        top: 10,
      ),
      child: SizedBox(
        height: 40,
        child: FutureBuilder(
          future: futureWithCourses,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || refreshing) {
              List<String> data = ["CORSO A", "CORSO B", "CORSO C"];
              int randomIdx = Random().nextInt(data.length - 1);

              return Skeletonizer(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: FilterChip(
                        label: Text(data[index]),
                        selected: randomIdx == index,
                        onSelected: (bool value) {},
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  },
                ),
              );
            }

            List<String> data = snapshot.data ?? [];
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: FilterChip(
                    label: Text(data[index]),
                    selected: !internalAPI.filteringCourses.contains(data[index]),
                    onSelected: (bool value) {
                      if (value) {
                        internalAPI.removeFilteringCourse(data[index]);
                      } else {
                        internalAPI.addFilteringCourse(data[index]);
                      }
                      updateHomeWidget();
                      setState(() {});
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      currentDate = DateTime.now().add(Duration(days: page - currentPageValue));
      _controller.animateToDate(currentDate);
    });
  }

  Widget body() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        timeLine(),
        filterList(),
        eventsList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemeSwitchingArea(
      child: Scaffold(
        appBar: appBar(),
        body: body(),
      ),
    );
  }
}
