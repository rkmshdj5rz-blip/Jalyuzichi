import sys
p=sys.argv[1]
s=open(p).read()
old='_flutter.loader.load();'
new='''_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    // Avval saqlangan ma'lumotlar qaytarilsin (jalyuzichi.html).
    try { await window.__jzReady; } catch (e) {}
    const appRunner = await engineInitializer.initializeEngine({
      hostElement: document.getElementById('app'),
    });
    await appRunner.runApp();
    const splash = document.getElementById('splash');
    if (splash) splash.remove();
  },
});'''
assert s.count(old)==1
open(p,'w').write(s.replace(old,new))
