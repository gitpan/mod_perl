package Apache::ConstantsTable;

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ! WARNING: generated by Apache::ParseSource/0.02
# !          Thu Aug 12 17:10:15 2004
# !          do NOT edit, any changes will be lost !
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

$Apache::ConstantsTable = {
  'ModPerl' => {
    'common' => [
      'MODPERL_RC_EXIT'
    ]
  },
  'Apache' => {
    'types' => [
      'DIR_MAGIC_TYPE'
    ],
    'satisfy' => [
      'SATISFY_ALL',
      'SATISFY_ANY',
      'SATISFY_NOSPEC'
    ],
    'remotehost' => [
      'REMOTE_HOST',
      'REMOTE_NAME',
      'REMOTE_NOLOOKUP',
      'REMOTE_DOUBLE_REV'
    ],
    'platform' => [
      'LF',
      'CR',
      'CRLF'
    ],
    'override' => [
      'OR_NONE',
      'OR_LIMIT',
      'OR_OPTIONS',
      'OR_FILEINFO',
      'OR_AUTHCFG',
      'OR_INDEXES',
      'OR_UNSET',
      'ACCESS_CONF',
      'RSRC_CONF',
      'OR_ALL'
    ],
    'options' => [
      'OPT_NONE',
      'OPT_INDEXES',
      'OPT_INCLUDES',
      'OPT_SYM_LINKS',
      'OPT_EXECCGI',
      'OPT_UNSET',
      'OPT_INCNOEXEC',
      'OPT_SYM_OWNER',
      'OPT_MULTI',
      'OPT_ALL'
    ],
    'mpmq' => [
      'AP_MPMQ_NOT_SUPPORTED',
      'AP_MPMQ_STATIC',
      'AP_MPMQ_DYNAMIC',
      'AP_MPMQ_STARTING',
      'AP_MPMQ_RUNNING',
      'AP_MPMQ_STOPPING',
      'AP_MPMQ_MAX_DAEMON_USED',
      'AP_MPMQ_IS_THREADED',
      'AP_MPMQ_IS_FORKED',
      'AP_MPMQ_HARD_LIMIT_DAEMONS',
      'AP_MPMQ_HARD_LIMIT_THREADS',
      'AP_MPMQ_MAX_THREADS',
      'AP_MPMQ_MIN_SPARE_DAEMONS',
      'AP_MPMQ_MIN_SPARE_THREADS',
      'AP_MPMQ_MAX_SPARE_DAEMONS',
      'AP_MPMQ_MAX_SPARE_THREADS',
      'AP_MPMQ_MAX_REQUESTS_DAEMON',
      'AP_MPMQ_MAX_DAEMONS',
      'AP_MPMQ_MPM_STATE'
    ],
    'methods' => [
      'M_GET',
      'M_PUT',
      'M_POST',
      'M_DELETE',
      'M_CONNECT',
      'M_OPTIONS',
      'M_TRACE',
      'M_PATCH',
      'M_PROPFIND',
      'M_PROPPATCH',
      'M_MKCOL',
      'M_COPY',
      'M_MOVE',
      'M_LOCK',
      'M_UNLOCK',
      'M_VERSION_CONTROL',
      'M_CHECKOUT',
      'M_UNCHECKOUT',
      'M_CHECKIN',
      'M_UPDATE',
      'M_LABEL',
      'M_REPORT',
      'M_MKWORKSPACE',
      'M_MKACTIVITY',
      'M_BASELINE_CONTROL',
      'M_MERGE',
      'M_INVALID',
      'METHODS'
    ],
    'log' => [
      'APLOG_EMERG',
      'APLOG_ALERT',
      'APLOG_CRIT',
      'APLOG_ERR',
      'APLOG_WARNING',
      'APLOG_NOTICE',
      'APLOG_INFO',
      'APLOG_DEBUG',
      'APLOG_LEVELMASK',
      'APLOG_TOCLIENT',
      'APLOG_STARTUP'
    ],
    'input_mode' => [
      'AP_MODE_READBYTES',
      'AP_MODE_GETLINE',
      'AP_MODE_EATCRLF',
      'AP_MODE_SPECULATIVE',
      'AP_MODE_EXHAUSTIVE',
      'AP_MODE_INIT'
    ],
    'http' => [
      'HTTP_CONTINUE',
      'HTTP_SWITCHING_PROTOCOLS',
      'HTTP_PROCESSING',
      'HTTP_OK',
      'HTTP_CREATED',
      'HTTP_ACCEPTED',
      'HTTP_NON_AUTHORITATIVE',
      'HTTP_NO_CONTENT',
      'HTTP_RESET_CONTENT',
      'HTTP_PARTIAL_CONTENT',
      'HTTP_MULTI_STATUS',
      'HTTP_MULTIPLE_CHOICES',
      'HTTP_MOVED_PERMANENTLY',
      'HTTP_MOVED_TEMPORARILY',
      'HTTP_SEE_OTHER',
      'HTTP_NOT_MODIFIED',
      'HTTP_USE_PROXY',
      'HTTP_TEMPORARY_REDIRECT',
      'HTTP_BAD_REQUEST',
      'HTTP_UNAUTHORIZED',
      'HTTP_PAYMENT_REQUIRED',
      'HTTP_FORBIDDEN',
      'HTTP_NOT_FOUND',
      'HTTP_METHOD_NOT_ALLOWED',
      'HTTP_NOT_ACCEPTABLE',
      'HTTP_PROXY_AUTHENTICATION_REQUIRED',
      'HTTP_REQUEST_TIME_OUT',
      'HTTP_CONFLICT',
      'HTTP_GONE',
      'HTTP_LENGTH_REQUIRED',
      'HTTP_PRECONDITION_FAILED',
      'HTTP_REQUEST_ENTITY_TOO_LARGE',
      'HTTP_REQUEST_URI_TOO_LARGE',
      'HTTP_UNSUPPORTED_MEDIA_TYPE',
      'HTTP_RANGE_NOT_SATISFIABLE',
      'HTTP_EXPECTATION_FAILED',
      'HTTP_UNPROCESSABLE_ENTITY',
      'HTTP_LOCKED',
      'HTTP_FAILED_DEPENDENCY',
      'HTTP_UPGRADE_REQUIRED',
      'HTTP_INTERNAL_SERVER_ERROR',
      'HTTP_NOT_IMPLEMENTED',
      'HTTP_BAD_GATEWAY',
      'HTTP_SERVICE_UNAVAILABLE',
      'HTTP_GATEWAY_TIME_OUT',
      'HTTP_VARIANT_ALSO_VARIES',
      'HTTP_INSUFFICIENT_STORAGE',
      'HTTP_NOT_EXTENDED'
    ],
    'filter_type' => [
      'AP_FTYPE_RESOURCE',
      'AP_FTYPE_CONTENT_SET',
      'AP_FTYPE_PROTOCOL',
      'AP_FTYPE_TRANSCODE',
      'AP_FTYPE_CONNECTION',
      'AP_FTYPE_NETWORK'
    ],
    'context' => [
      'NOT_IN_VIRTUALHOST',
      'NOT_IN_LIMIT',
      'NOT_IN_DIRECTORY',
      'NOT_IN_LOCATION',
      'NOT_IN_FILES',
      'NOT_IN_DIR_LOC_FILE',
      'GLOBAL_ONLY'
    ],
    'conn_keepalive' => [
      'AP_CONN_UNKNOWN',
      'AP_CONN_CLOSE',
      'AP_CONN_KEEPALIVE'
    ],
    'config' => [
      'DECLINE_CMD'
    ],
    'common' => [
      'DECLINED',
      'DONE',
      'OK',
      'NOT_FOUND',
      'FORBIDDEN',
      'AUTH_REQUIRED',
      'SERVER_ERROR',
      'REDIRECT'
    ],
    'cmd_how' => [
      'RAW_ARGS',
      'TAKE1',
      'TAKE2',
      'ITERATE',
      'ITERATE2',
      'FLAG',
      'NO_ARGS',
      'TAKE12',
      'TAKE3',
      'TAKE23',
      'TAKE123',
      'TAKE13'
    ]
  },
  'APR' => {
    'uri' => [
      'APR_URI_FTP_DEFAULT_PORT',
      'APR_URI_SSH_DEFAULT_PORT',
      'APR_URI_TELNET_DEFAULT_PORT',
      'APR_URI_GOPHER_DEFAULT_PORT',
      'APR_URI_HTTP_DEFAULT_PORT',
      'APR_URI_POP_DEFAULT_PORT',
      'APR_URI_NNTP_DEFAULT_PORT',
      'APR_URI_IMAP_DEFAULT_PORT',
      'APR_URI_PROSPERO_DEFAULT_PORT',
      'APR_URI_WAIS_DEFAULT_PORT',
      'APR_URI_LDAP_DEFAULT_PORT',
      'APR_URI_HTTPS_DEFAULT_PORT',
      'APR_URI_RTSP_DEFAULT_PORT',
      'APR_URI_SNEWS_DEFAULT_PORT',
      'APR_URI_ACAP_DEFAULT_PORT',
      'APR_URI_NFS_DEFAULT_PORT',
      'APR_URI_TIP_DEFAULT_PORT',
      'APR_URI_SIP_DEFAULT_PORT',
      'APR_URI_UNP_OMITSITEPART',
      'APR_URI_UNP_OMITUSER',
      'APR_URI_UNP_OMITPASSWORD',
      'APR_URI_UNP_OMITUSERINFO',
      'APR_URI_UNP_REVEALPASSWORD',
      'APR_URI_UNP_OMITPATHINFO',
      'APR_URI_UNP_OMITQUERY'
    ],
    'table' => [
      'APR_OVERLAP_TABLES_SET',
      'APR_OVERLAP_TABLES_MERGE'
    ],
    'status' => [
      'APR_TIMEUP'
    ],
    'socket' => [
      'APR_SO_LINGER',
      'APR_SO_KEEPALIVE',
      'APR_SO_DEBUG',
      'APR_SO_NONBLOCK',
      'APR_SO_REUSEADDR',
      'APR_SO_SNDBUF',
      'APR_SO_RCVBUF',
      'APR_SO_DISCONNECTED'
    ],
    'shutdown_how' => [
      'APR_SHUTDOWN_READ',
      'APR_SHUTDOWN_WRITE',
      'APR_SHUTDOWN_READWRITE'
    ],
    'read_type' => [
      'APR_BLOCK_READ',
      'APR_NONBLOCK_READ'
    ],
    'poll' => [
      'APR_POLLIN',
      'APR_POLLPRI',
      'APR_POLLOUT',
      'APR_POLLERR',
      'APR_POLLHUP',
      'APR_POLLNVAL'
    ],
    'lockmech' => [
      'APR_LOCK_FCNTL',
      'APR_LOCK_FLOCK',
      'APR_LOCK_SYSVSEM',
      'APR_LOCK_PROC_PTHREAD',
      'APR_LOCK_POSIXSEM',
      'APR_LOCK_DEFAULT'
    ],
    'limit' => [
      'APR_LIMIT_CPU',
      'APR_LIMIT_MEM',
      'APR_LIMIT_NPROC',
      'APR_LIMIT_NOFILE'
    ],
    'hook' => [
      'APR_HOOK_REALLY_FIRST',
      'APR_HOOK_FIRST',
      'APR_HOOK_MIDDLE',
      'APR_HOOK_LAST',
      'APR_HOOK_REALLY_LAST'
    ],
    'flock' => [
      'APR_FLOCK_SHARED',
      'APR_FLOCK_EXCLUSIVE',
      'APR_FLOCK_TYPEMASK',
      'APR_FLOCK_NONBLOCK'
    ],
    'finfo' => [
      'APR_FINFO_LINK',
      'APR_FINFO_MTIME',
      'APR_FINFO_CTIME',
      'APR_FINFO_ATIME',
      'APR_FINFO_SIZE',
      'APR_FINFO_CSIZE',
      'APR_FINFO_DEV',
      'APR_FINFO_INODE',
      'APR_FINFO_NLINK',
      'APR_FINFO_TYPE',
      'APR_FINFO_USER',
      'APR_FINFO_GROUP',
      'APR_FINFO_UPROT',
      'APR_FINFO_GPROT',
      'APR_FINFO_WPROT',
      'APR_FINFO_ICASE',
      'APR_FINFO_NAME',
      'APR_FINFO_MIN',
      'APR_FINFO_IDENT',
      'APR_FINFO_OWNER',
      'APR_FINFO_PROT',
      'APR_FINFO_NORM',
      'APR_FINFO_DIRENT'
    ],
    'filetype' => [
      'APR_NOFILE',
      'APR_REG',
      'APR_DIR',
      'APR_CHR',
      'APR_BLK',
      'APR_PIPE',
      'APR_LNK',
      'APR_SOCK',
      'APR_UNKFILE'
    ],
    'fileperms' => [
      'APR_UREAD',
      'APR_UWRITE',
      'APR_UEXECUTE',
      'APR_GREAD',
      'APR_GWRITE',
      'APR_GEXECUTE',
      'APR_WREAD',
      'APR_WWRITE',
      'APR_WEXECUTE'
    ],
    'filepath' => [
      'APR_FILEPATH_NOTABOVEROOT',
      'APR_FILEPATH_SECUREROOTTEST',
      'APR_FILEPATH_SECUREROOT',
      'APR_FILEPATH_NOTRELATIVE',
      'APR_FILEPATH_NOTABSOLUTE',
      'APR_FILEPATH_NATIVE',
      'APR_FILEPATH_TRUENAME',
      'APR_FILEPATH_ENCODING_UNKNOWN',
      'APR_FILEPATH_ENCODING_LOCALE',
      'APR_FILEPATH_ENCODING_UTF8'
    ],
    'filemode' => [
      'APR_READ',
      'APR_WRITE',
      'APR_CREATE',
      'APR_APPEND',
      'APR_TRUNCATE',
      'APR_BINARY',
      'APR_EXCL',
      'APR_BUFFERED',
      'APR_DELONCLOSE'
    ],
    'error' => [
      'APR_ENOSTAT',
      'APR_ENOPOOL',
      'APR_EBADDATE',
      'APR_EINVALSOCK',
      'APR_ENOPROC',
      'APR_ENOTIME',
      'APR_ENODIR',
      'APR_ENOLOCK',
      'APR_ENOPOLL',
      'APR_ENOSOCKET',
      'APR_ENOTHREAD',
      'APR_ENOTHDKEY',
      'APR_EGENERAL',
      'APR_ENOSHMAVAIL',
      'APR_EBADIP',
      'APR_EBADMASK',
      'APR_EDSOOPEN',
      'APR_EABSOLUTE',
      'APR_ERELATIVE',
      'APR_EINCOMPLETE',
      'APR_EABOVEROOT',
      'APR_EBADPATH',
      'APR_EPATHWILD',
      'APR_ESYMNOTFOUND',
      'APR_EPROC_UNKNOWN',
      'APR_EOF',
      'APR_EINIT',
      'APR_ENOTIMPL',
      'APR_EMISMATCH',
      'APR_EBUSY',
      'APR_EACCES',
      'APR_EEXIST',
      'APR_ENAMETOOLONG',
      'APR_ENOENT',
      'APR_ENOTDIR',
      'APR_ENOSPC',
      'APR_ENOMEM',
      'APR_EMFILE',
      'APR_ENFILE',
      'APR_EBADF',
      'APR_EINVAL',
      'APR_ESPIPE',
      'APR_EAGAIN',
      'APR_EINTR',
      'APR_ENOTSOCK',
      'APR_ECONNREFUSED',
      'APR_EINPROGRESS',
      'APR_ECONNABORTED',
      'APR_ECONNRESET',
      'APR_ETIMEDOUT',
      'APR_EHOSTUNREACH',
      'APR_ENETUNREACH',
      'APR_EFTYPE',
      'APR_EPIPE',
      'APR_EXDEV',
      'APR_ENOTEMPTY',
      'APR_END'
    ],
    'common' => [
      'APR_SUCCESS'
    ]
  }
};


1;
