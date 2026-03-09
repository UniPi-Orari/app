{{flutter_js}}
{{flutter_build_config}}

const progress = document.querySelector(".progress-value");
const progressBar = document.querySelector(".progress");
const progressText = document.querySelector(".progress-text");

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    progress.style.animation = "none";
    progress.style.width = "66%";

    const appRunner = await engineInitializer.initializeEngine();
    progress.style.width = "99%";

    await new Promise((resolve) => setTimeout(resolve, 500));
    progressBar.style.opacity = 0;
    progressText.style.opacity = 0;

    await appRunner.runApp();
    document.querySelector("flutter-view").classList.add("fade-in");
  }
});