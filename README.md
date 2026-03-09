# UniPi Orario


<img width=222 src="assets/readme_stuff/icon.png" />

made with ❤️ by [ale](https://github.com/aleeeee1) and [zubby](https://github.com/zubbyy)

<br />

UniPi Orario allows you to visualize your (maybe!) university timetable in a more intuitive way. \
It is designed to be simple and easy to use, with a clean and modern interface, built with Material You design in mind.

# Screenshots

<details>
    <summary>Images</summary>
    <img width=200 src="assets/readme_stuff/screenshots/1.png" />
    <img width=200 src="assets/readme_stuff/screenshots/2.png" />
    <img width=200 src="assets/readme_stuff/screenshots/3.png" />
    <img width=200 src="assets/readme_stuff/screenshots/4.png" />
    <img width=200 src="assets/readme_stuff/screenshots/5.png" />
    <img width=200 src="assets/readme_stuff/screenshots/6.png" />
    <img width=200 src="assets/readme_stuff/screenshots/7.png" />
    <img width=200 src="assets/readme_stuff/screenshots/8.png" />

</details>

# Features
- ✅ Works on iOS, Android and Web!
- 📅 Daily view
- ❓ Filter by course
- 📲 Native widget support
- 🕒 Add your own events
- 🧠 Efficiently caches/retrieves results in internal db                   
- 🎨 Material You design (dynamic colors, themed icon on A12+)
- 🌐 Multi-language support

# TODOs
- Crowdin integration
- Editing timetable, customizing events (e.g. posticipate a lesson)
- Export events on calendar
- You tell me :\)

# Known issues
- No clue about the timetable format of other courses, so it might not work for yours.
- When you change theme, date will reset to today.

> [!IMPORTANT]
> **How to try using your own calendar**
> if you have a calendar like
> ```
> https://unipi.prod.up.cineca.it/calendarioPubblico/linkCalendarioId=xxxxxxxxxxxxxxxxxxxxxxxx
> ```
> 
> copy the calendar id and long press the refresh icon: a dialog will appear, paste the id and press ok.


> [!NOTE]
> probably it won't work :c

# Download the app
You can download the app from [release page](https://github.com/UniPi-Orari/app/releases/latest)

**You can also use the website version [here](https://unipi-orari.github.io/app) and install it as a PWA on your device.**

# Building from source

### Android

```
flutter build apk
```

Yeah `flutter pub get` isn't really necessary, since it gets executed by `flutter build apk` anyway.

### iOS

You can generate an .ipa file by running:

```
build_ios.sh
```

You will need to be on a macOS machine with Xcode installed, logged in with a valid Team Account (which is not a Developer Account).

To install the app on your device, you can use the generated .ipa with [SideStore](https://github.com/SideStore) or whatever method you prefer.
