import core.runtime;

//alias extern(C) void function() functype;

version(Posix) {
    extern(C) void* dlsym(void*, const char*);
    extern(C) void* dlopen(const char*, int);
    extern(C) char* dlerror();

    pragma(lib, "dl");
} else version(Windows) {
    extern(Windows) void* LoadLibraryA(const char* filename);
    extern(Windows) void* GetProcAddress(void*, const char*);
    
}
