*** modules.c~
--- modules.c
***************
*** 22,27 ****
--- 22,28 ----
  extern module action_module;
  extern module browser_module;
  extern module proxy_module;
+ extern module perl_module;
  
  module *prelinked_modules[] = {
    &core_module,
***************
*** 41,46 ****
--- 42,48 ----
    &action_module,
    &browser_module,
    &proxy_module,
+   &perl_module,
    NULL
  };
  module *preloaded_modules[] = {
***************
*** 61,65 ****
--- 63,68 ----
    &action_module,
    &browser_module,
    &proxy_module,
+   &perl_module,
    NULL
  };
