# -*- mode: python; coding: utf-8 -*-

import SCons.Util
import re

gperf = Builder(action = 'gperf $SOURCE > $TARGET',
                suffix = '.c',
                src_suffix = '.gperf')

# taken from http://scons.tigris.org/ds/viewMessage.do?dsForumId=1268&dsMessageId=2824057

def VersionedSharedLibrary(env, libname, libversion, lib_objs=[], parse_flags=[]):
    platform = env.subst('$PLATFORM')
    shlib_pre_action = None
    shlib_suffix = env.subst('$SHLIBSUFFIX')
    shlib_post_action = None
    shlink_flags = SCons.Util.CLVar(env.subst('$SHLINKFLAGS'))

    if platform == 'posix':
        shlib_post_action = ['rm -f $TARGET','ln -s ${SOURCE.file} $TARGET']
        shlib_post_action_output_re = [
            '%s\\.[0-9\\.]*$' % re.escape(shlib_suffix),
            shlib_suffix ]
        shlib_suffix += '.' + libversion
        (major, age, revision) = libversion.split(".")
        soname = libname + "." + major
        shlink_flags += [ '-Wl,-Bsymbolic', '-Wl,-soname=%s' % soname ]
    elif platform == 'aix':
        shlib_pre_action = [
            "nm -Pg $SOURCES &gt; ${TARGET}.tmp1",
            "grep ' [BDT] ' &lt; ${TARGET}.tmp1 &gt; ${TARGET}.tmp2",
            "cut -f1 -d' ' &lt; ${TARGET}.tmp2 &gt; ${TARGET}",
            "rm -f ${TARGET}.tmp[12]" ]
        shlib_pre_action_output_re = [ '$', '.exp' ]
        shlib_post_action = [ 'rm -f $TARGET', 'ln -s $SOURCE $TARGET' ]
        shlib_post_action_output_re = [
            '%s\\.[0-9\\.]*' % re.escape(shlib_suffix),
            shlib_suffix ]
        shlib_suffix += '.' + libversion
        shlink_flags += ['-G', '-bE:${TARGET}.exp', '-bM:SRE']
    elif platform == 'cygwin':
        shlink_flags += [ '-Wl,-Bsymbolic',
                          '-Wl,--out-implib,$​{TARGET.base}.a' ]
    elif platform == 'darwin':
        shlib_suffix = '.' + libversion + shlib_suffix
        shlink_flags += [ '-current_version', '%s' % libversion,
                          '-undefined', 'dynamic_lookup' ]

    lib = env.SharedLibrary(libname,lib_objs,
                            SHLIBSUFFIX=shlib_suffix,
                            SHLINKFLAGS=shlink_flags, parse_flags=parse_flags)

    if shlib_pre_action:
        shlib_pre_action_output = re.sub(shlib_pre_action_output_re[0],
                                         shlib_pre_action_output_re[1],
                                         str(lib[0]))
        env.Command(shlib_pre_action_output, [ lib_objs ],
                     shlib_pre_action)
        env.Depends(lib, shlib_pre_action_output)
    if shlib_post_action:
        shlib_post_action_output = re.sub(shlib_post_action_output_re[0],
                                          shlib_post_action_output_re[1],
                                          str(lib[0]))
        env.Command(shlib_post_action_output, lib, shlib_post_action)
    return lib

def InstallVersionedSharedLibrary(env, destination, lib):
    platform = env.subst('$PLATFORM')
    shlib_suffix = env.subst('$SHLIBSUFFIX')
    shlib_install_pre_action = None
    shlib_install_post_action = None

    if platform == 'posix':
        shlib_post_action = [ 'rm -f $TARGET',
                              'ln -s ${SOURCE.file} $TARGET' ]
        shlib_post_action_output_re = ['%s\\.[0-9\\.]*$' % re.escape(shlib_suffix),
                                       shlib_suffix ]
        shlib_install_post_action = shlib_post_action
        shlib_install_post_action_output_re = shlib_post_action_output_re

    ilib = env.Install(destination, lib)

    if shlib_install_pre_action:
        shlib_install_pre_action_output = re.sub(shlib_install_pre_action_output_re[0],
                                                 shlib_install_pre_action_output_re[1],
                                                 str(ilib[0]))
        env.Command(shlib_install_pre_action_output, ilib,
                    shlib_install_pre_action)
        env.Depends(shlib_install_pre_action_output, ilib)

    if shlib_install_post_action:
        shlib_install_post_action_output = re.sub(shlib_install_post_action_output_re[0],
                                                  shlib_install_post_action_output_re[1],
                                                  str(ilib[0]))
        env.Command(shlib_install_post_action_output, ilib,
                    shlib_install_post_action)
    return ilib

vars = Variables()
vars.Add(PathVariable('DESTDIR',
                      'Destination directory',
                      '',
                      PathVariable.PathAccept))
vars.Add(PathVariable('PREFIX',
                      'prefix',
                      '/usr',
                      PathVariable.PathAccept))
vars.Add(PathVariable('_bindir',
                      'Directory to install binaries',
                      '${PREFIX}/bin',
                      PathVariable.PathAccept))
vars.Add(PathVariable('_libdir',
                      'Directory to install shared library',
                      '${PREFIX}/lib',
                      PathVariable.PathAccept))
vars.Add(PathVariable('_includedir',
                      'Directory to install development headers',
                      '${PREFIX}/include',
                      PathVariable.PathAccept))

env = Environment(BUILDERS = {'GPerf': gperf},
                  variables = vars)

Help(vars.GenerateHelpText(env))                              

def CheckPKGConfig(context, version):
    context.Message( 'Checking for pkg-config %s or newer... ' % version )
    ret = context.TryAction('pkg-config --atleast-pkgconfig-version=%s' % version)[0]
    context.Result( ret )
    return ret

def CheckPKG(context, name):
    context.Message( 'Checking for %s... ' % name )
    ret = context.TryAction('pkg-config --exists \'%s\'' % name)[0]
    context.Result( ret )
    return ret

def CheckGPerf(context):
    context.Message('Checking for GPerf 3.0.3 or newer... ')
    ok, output = context.TryAction('gperf --version > $TARGET 2>&1')
    if ok:
        match = re.search(r'GNU gperf (\d+)\.(\d+)\.(\d+)', output, re.IGNORECASE | re.MULTILINE)
        if match:
            version = map(int, match.groups())
            if version >= [3, 0, 3]:
                context.Result(1)
                return 1
    context.Result(0)
    return 0

# Configuration:

conf = Configure(env, custom_tests = {'CheckPKGConfig': CheckPKGConfig,
                                      'CheckPKG': CheckPKG,
                                      'CheckGPerf': CheckGPerf})

if not conf.CheckPKGConfig('0.15.0'):
    print 'pkg-config >= 0.15.0 not found.'
    Exit(1)
    
if not conf.CheckPKG('libevent'):
    print 'libevent not found.'
    Exit(1)

if not conf.CheckPKG('tokyocabinet'):
    print 'tokyocabinet not found.'
    Exit(1)

if not conf.CheckPKG('libpcre'):
    print 'pcre not found.'
    Exit(1)

if not conf.CheckGPerf():
    Exit(1)

env = conf.Finish()

env.ParseConfig('pkg-config --cflags --libs tokyocabinet')
env.ParseConfig('pkg-config --cflags --libs libpcre')
env.ParseConfig('pkg-config --cflags --libs libevent')
env.Append(LIBS=['dl'])

platform = env.backtick('uname -o 2>/dev/null || uname -s').replace('/', '')
env.Append(CCFLAGS = '-DPLATFORM_%s' % platform)

grok_version_h = env.Command(target = 'grok_version.h',
                             source = 'version.sh',
                             action = 'sh version.sh --header > $TARGET')

env.AlwaysBuild(grok_version_h)

filters_c = env.GPerf(source = 'filters.gperf')
grok_matchconf_macro_c = env.GPerf(source = 'grok_matchconf_macro.gperf')

grok_capture_xdr_c = env.RPCGenXDR(target = 'grok_capture_xdr.c', source = 'grok_capture.x')
grok_capture_xdr_h = env.RPCGenHeader(target = 'grok_capture_xdr.h', source = 'grok_capture.x')

libgrok = VersionedSharedLibrary(env, 'grok', '1.0.0', ['grok.c',
                                                        'grokre.c',
                                                        'grok_capture.c',
                                                        grok_capture_xdr_c,
                                                        'grok_pattern.c',
                                                        'stringhelper.c',
                                                        'predicates.c',
                                                        'grok_match.c',
                                                        'grok_logging.c',
                                                        'grok_program.c',
                                                        'grok_input.c',
                                                        'grok_matchconf.c',
                                                        'libc_helper.c',
                                                        grok_matchconf_macro_c,
                                                        filters_c,
                                                        'grok_discover.c'])

InstallVersionedSharedLibrary(env, '${DESTDIR}${_libdir}', libgrok)

conf_yy = env.CFile(target = 'conf.yy.c',
                    source = 'conf.y')

conf_tab = env.CFile(target = 'conf.tab.c',
                     source = 'conf.lex')

grok = env.Program(target = 'grok',
                   source = ['main.c',
                             'grok_config.c',
                             conf_yy,
                             conf_tab,
                             libgrok])
env.Install('${DESTDIR}${_bindir}', grok)

discogrok = env.Program(target = 'discogrok',
                        source = ['discover_main.c',
                                  libgrok])
env.Install('${DESTDIR}${_bindir}', discogrok)

env.Install('${DESTDIR}${_includedir}', ['grok.h',
                                         'grok_pattern.h',
                                         'grok_capture.h',
                                         grok_capture_xdr_h,
                                         'grok_match.h',
                                         'grok_logging.h',
                                         'grok_discover.h',
                                         grok_version_h])

env.Alias('install', '${DESTDIR}${_bindir}')
env.Alias('install', '${DESTDIR}${_includedir}')
env.Alias('install', '${DESTDIR}${_libdir}')
