/* Copyright 2000-2004 The Apache Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef MODPERL_LOG_H
#define MODPERL_LOG_H

#define MP_STRINGIFY(n) MP_STRINGIFY_HELPER(n)
#define MP_STRINGIFY_HELPER(n) #n

#ifdef MP_TRACE
#   if defined(__GNUC__)
#      if (__GNUC__ > 2)
#         define MP_FUNC __func__
#      else
#         define MP_FUNC __FUNCTION__
#      endif
#   else
#      define MP_FUNC __FILE__ ":" MP_STRINGIFY(__LINE__)
#   endif
#else
#   define MP_FUNC NULL
#endif

#include "modperl_trace.h"

#ifdef _PTHREAD_H
#define modperl_thread_self() pthread_self()
#else
#define modperl_thread_self() 0
#endif

#define MP_TIDF \
(unsigned long)modperl_thread_self()

void modperl_trace_logfile_set(apr_file_t *logfile_new);
    
unsigned long modperl_debug_level(void);

#ifdef WIN32
#define MP_debug_level modperl_debug_level()
#else
extern unsigned long MP_debug_level;
#endif

void modperl_trace(const char *func, const char *fmt, ...);

void modperl_trace_level_set(server_rec *s, const char *level);

#define modperl_log_warn(s,msg) \
    ap_log_error(APLOG_MARK, APLOG_WARNING, 0, s, "%s", msg)

#define modperl_log_error(s,msg) \
    ap_log_error(APLOG_MARK, APLOG_ERR, 0, s, "%s", msg)

#define modperl_log_notice(s,msg) \
    ap_log_error(APLOG_MARK, APLOG_NOTICE, 0, s, "%s", msg)

#define modperl_log_debug(s,msg) \
    ap_log_error(APLOG_MARK, APLOG_DEBUG, 0, s, "%s", msg)

#define modperl_log_reason(r,msg,file) \
    ap_log_error(APLOG_MARK, APLOG_ERR, 0, r->server, \
                 "access to %s failed for %s, reason: %s", \
                 file, \
                 get_remote_host(r->connection, \
                 r->per_dir_config, REMOTE_NAME), \
                 msg)

#endif /* MODPERL_LOG_H */
