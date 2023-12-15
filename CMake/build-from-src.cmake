# Note: Be aware of the differences between CMake project and Makefile project.
# Makefile project is not able to get BINARY_DIR at configuration.

set(actually_built)

if (PHOTON_ENABLE_CPM)
    include(CMake/CPM.cmake)

    if (PHOTON_BUILD_TESTING)
        CPMAddPackage(
            NAME gflags
            GITHUB_REPOSITORY gflags/gflags
            VERSION 2.2.2
            OPTIONS "GFLAGS_IS_SUBPROJECT YES"
                    "BUILD_SHARED_LIBS NO"
                    "BUILD_STATIC_LIBS YES"
        )

        if(gflags_ADDED)
            include_directories(${gflags_BINARY_DIR}/include)
            set(GFLAGS_INCLUDE_DIRS ${gflags_BINARY_DIR}/include)
        endif()
    endif()

    CPMAddPackage(
        NAME zlib
        GITHUB_REPOSITORY Bisque-IO/zlib
        VERSION 1.3.0.1
        OPTIONS "ZLIB_ENABLE_TESTING OFF"
                "ZLIB_BUILD_EXAMPLES OFF"
                "ZLIB_BUILD_SHARED OFF"
    )
    if (zlib_ADDED)
        set_property(TARGET zlibstatic PROPERTY POSITION_INDEPENDENT_CODE ON)
        include_directories(${zlib_SOURCE_DIR} ${zlib_BINARY_DIR})
        set(ZLIB_LIBRARIES ${zlib_BINARY_DIR}/libz.a)
        set(ZLIB_INCLUDE_DIRS ${zlib_SOURCE_DIR} ${zlib_BINARY_DIR})
        set(ZLIB_LIBRARY ${zlib_BINARY_DIR}/libz.a)
        set(ZLIB_INCLUDE_DIR ${zlib_SOURCE_DIR} &{zlib_BINARY_DIR})
        add_library(ZLIB::ZLIB ALIAS zlibstatic)
        add_library(ZLIB ALIAS zlibstatic)
        set(ZLIB_ROOT_DIR ${zlib_BINARY_DIR})

        list(APPEND actually_built zlib)
    endif()

    if (CMAKE_SYSTEM_NAME MATCHES "Linux")
        CPMAddPackage(
            NAME aio
            GIT_REPOSITORY https://pagure.io/libaio.git
            GIT_TAG libaio-0.3.113
            DOWNLOAD_ONLY
        )
        if (aio_ADDED)
            include_directories(${aio_SOURCE_DIR}/src)
            add_custom_target(build_aio
                COMMAND test -e "${aio_SOURCE_DIR}/src/libaio.a" || make
                WORKING_DIRECTORY ${aio_SOURCE_DIR}/src
                BYPRODUCTS ${aio_SOURCE_DIR}/src/libaio.a
                VERBATIM
            )
            add_library(aio STATIC IMPORTED)
            set_target_properties(aio PROPERTIES
                IMPORTED_LOCATION ${aio_SOURCE_DIR}/src/libaio.a
                INTERFACE_INCLUDE_DIRECTORIES ${aio_SOURCE_DIR}/src
            )
            add_dependencies(aio build_aio)
            set(AIO_ROOT_DIR ${aio_SOURCE_DIR})
            set(AIO_LIBRARIES ${aio_SOURCE_DIR}/src/libaio.a)
            set(AIO_INCLUDE_DIRS ${aio_SOURCE_DIR}/src)
            list(APPEND actually_built aio)
        endif()
    endif()

    if (PHOTON_ENABLE_URING AND CMAKE_SYSTEM_NAME MATCHES "Linux")
        CPMAddPackage(
            NAME uring
            GITHUB_REPOSITORY axboe/liburing
            GIT_TAG liburing-2.5
            DOWNLOAD_ONLY
        )
        if (uring_ADDED)
            include_directories(${uring_SOURCE_DIR}/src/include)
            add_custom_target(build_uring
                COMMAND test -e "${uring_SOURCE_DIR}/src/liburing.a" || sh ${uring_SOURCE_DIR}/configure
                COMMAND test -e "${uring_SOURCE_DIR}/src/liburing.a" || make
                WORKING_DIRECTORY ${uring_SOURCE_DIR}/src
                BYPRODUCTS ${uring_SOURCE_DIR}/src/liburing.a
                VERBATIM
            )
            add_library(uring STATIC IMPORTED)
            set_target_properties(uring PROPERTIES
                IMPORTED_LOCATION ${uring_SOURCE_DIR}/src/liburing.a
                INTERFACE_INCLUDE_DIRECTORIES ${uring_SOURCE_DIR}/src/include
            )
            add_dependencies(uring build_uring)
            set(URING_ROOT_DIR ${uring_SOURCE_DIR})
            set(URING_LIBRARIES ${uring_SOURCE_DIR}/src/liburing.a)
            set(URING_INCLUDE_DIRS ${uring_SOURCE_DIR}/src/include)
            list(APPEND actually_built uring)
        endif()
    endif()

    CPMAddPackage(
        NAME openssl
        GITHUB_REPOSITORY janbar/openssl-cmake
        GIT_TAG 1.1.1w-20231130
        OPTIONS "WITH_APPS OFF"
    )
    if (openssl_ADDED)
        set_property(TARGET ssl PROPERTY POSITION_INDEPENDENT_CODE ON)
        set_property(TARGET crypto PROPERTY POSITION_INDEPENDENT_CODE ON)
        include_directories(${openssl_SOURCE_DIR}/include)
        include_directories(${openssl_BINARY_DIR}/include)
        set(OPENSSL_INCLUDE_DIR ${openssl_SOURCE_DIR}/include ${openssl_BINARY_DIR}/include)
        set(OPENSSL_INCLUDE_DIRS ${openssl_SOURCE_DIR}/include ${openssl_BINARY_DIR}/include)
        add_library(OpenSSL::Crypto ALIAS crypto)
        add_library(OpenSSL::SSL ALIAS ssl)
        set(OPENSSL_SSL_LIBRARIES ${openssl_BINARY_DIR}/ssl/libssl.a)
        set(OPENSSL_SSL_LIBRARY ${openssl_BINARY_DIR}/ssl/libssl.a)
        set(OPENSSL_CRYPTO_LIBRARIES ${openssl_BINARY_DIR}/crypto/libcrypto.a)
        set(OPENSSL_CRYPTO_LIBRARY ${openssl_BINARY_DIR}/crypto/libcrypto.a)
        set(OPENSSL_ROOT_DIR ${openssl_SOURCE_DIR} ${openssl_BINARY_DIR} ${openssl_BINARY_DIR}/crypto ${openssl_BINARY_DIR}/ssl)
        set(OPENSSL_LIBRARIES ${OPENSSL_SSL_LIBRARIES} ${OPENSSL_CRYPTO_LIBRARIES})
        set(OPENSSL_LIBRARY ${OPENSSL_SSL_LIBRARIES} ${OPENSSL_CRYPTO_LIBRARIES})
        list(APPEND actually_built crypto)
        list(APPEND actually_built ssl)
    endif()

    if (PHOTON_ENABLE_CURL)
        CPMAddPackage(
            NAME curl
            GITHUB_REPOSITORY curl/curl
            GIT_TAG curl-8_5_0
            OPTIONS "BUILD_STATIC_LIBS ON"
                    "BUILD_SHARED_LIBS OFF"
                    "BUILD_CURL_EXE OFF"
                    "BUILD_TESTING OFF"
                    "CURL_ENABLE_EXPORT_TARGET OFF"
                    "USE_LIBIDN2 OFF"
                    "CURL_DISABLE_FTP 0"
                    "CURL_DISABLE_SFTP 0"
                    "CURL_DISABLE_GOPHER 1"
                    "CURL_DISABLE_IMAP 1"
                    "CURL_DISABLE_LDAP 1"
                    "CURL_DISABLE_LDAPS 1"
                    "CURL_DISABLE_MQTT 1"
                    "CURL_DISABLE_NETRC 1"
                    "CURL_DISABLE_NTLM 1"
                    "CURL_DISABLE_POP3 1"
                    "CURL_DISABLE_SSH 0"
                    "CURL_DISABLE_SMB 1"
                    "CURL_DISABLE_SMBS 1"
                    "CURL_DISABLE_SMTP 1"
                    "CURL_DISABLE_SMTPS 1"
                    "CURL_DISABLE_TELNET 1"
                    "CURL_DISABLE_TFTP 1"
                    "CURL_DISABLE_KERBEROS_AUTH 0"
                    "CURL_DISABLE_HSTS 1"
                    "CURL_DISABLE_RTSP 1"
                    "CURL_DISABLE_ALTSVC 1"
                    "CURL_DISABLE_COOKIES 0"
                    "CURL_DISABLE_DICT 0"
                    "USE_LIBPSL 0"
                    "CURL_USE_LIBPSL 0"
                    "USE_LIBSSH2 0"
                    "CURL_USE_LIBSSH2 0"
                    "USE_LIBIDN2 0"
                    "CURL_USE_LIBIDN2 0"
                    "USE_WEBSOCKETS 1"
                    "CURL_DISABLE_OPENSSL_AUTO_LOAD_CONFIG OFF"
        )
        if (curl_ADDED)
            set_property(TARGET libcurl_static PROPERTY POSITION_INDEPENDENT_CODE ON)
            set(CURL_LIBRARIES ${curl_BINARY_DIR}/lib/libcurl.a)
            set(CURL_LIBRARY ${curl_BINARY_DIR}/lib/libcurl.a)
            set(CURL_INCLUDE_DIRS ${curl_SOURCE_DIR}/include)
            set(CURL_INCLUDE_DIR ${curl_SOURCE_DIR}/include)
            message("CURL_LIBRARIES: ${CURL_LIBRARIES}")
            add_library(curl ALIAS libcurl_static)
            list(APPEND actually_built curl)
        endif()
    endif()
endif()

function(build_from_src [dep])
    if (dep STREQUAL "aio")
        set(BINARY_DIR ${PROJECT_BINARY_DIR}/aio-build)
        ExternalProject_Add(
                aio
                URL ${PHOTON_AIO_SOURCE}
                URL_MD5 605237f35de238dfacc83bcae406d95d
                BUILD_IN_SOURCE ON
                CONFIGURE_COMMAND ""
                BUILD_COMMAND make prefix=${BINARY_DIR} install -j
                INSTALL_COMMAND ""
        )
        set(AIO_INCLUDE_DIRS ${BINARY_DIR}/include PARENT_SCOPE)
        set(AIO_LIBRARIES ${BINARY_DIR}/lib/libaio.a PARENT_SCOPE)

    elseif (dep STREQUAL "zlib")
        set(BINARY_DIR ${PROJECT_BINARY_DIR}/zlib-build)
        ExternalProject_Add(
                zlib
                URL ${PHOTON_ZLIB_SOURCE}
                URL_MD5 9b8aa094c4e5765dabf4da391f00d15c
                BUILD_IN_SOURCE ON
                CONFIGURE_COMMAND CFLAGS=-fPIC ./configure --prefix=${BINARY_DIR} --static
                BUILD_COMMAND make -j
                INSTALL_COMMAND make install
        )
        set(ZLIB_INCLUDE_DIRS ${BINARY_DIR}/include PARENT_SCOPE)
        set(ZLIB_LIBRARIES ${BINARY_DIR}/lib/libz.a PARENT_SCOPE)

    elseif (dep STREQUAL "uring")
        set(BINARY_DIR ${PROJECT_BINARY_DIR}/uring-build)
        ExternalProject_Add(
                uring
                URL ${PHOTON_URING_SOURCE}
                URL_MD5 2e8c3c23795415475654346484f5c4b8
                BUILD_IN_SOURCE ON
                CONFIGURE_COMMAND ./configure --prefix=${BINARY_DIR}
                BUILD_COMMAND V=1 CFLAGS=-fPIC make -C src
                INSTALL_COMMAND make install
        )
        set(URING_INCLUDE_DIRS ${BINARY_DIR}/include PARENT_SCOPE)
        set(URING_LIBRARIES ${BINARY_DIR}/lib/liburing.a PARENT_SCOPE)

    elseif (dep STREQUAL "gflags")
        ExternalProject_Add(
                gflags
                URL ${PHOTON_GFLAGS_SOURCE}
                URL_MD5 1a865b93bacfa963201af3f75b7bd64c
                CMAKE_ARGS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_POSITION_INDEPENDENT_CODE=ON
                INSTALL_COMMAND ""
        )
        if (CMAKE_BUILD_TYPE STREQUAL "Debug")
            set(POSTFIX "_debug")
        endif ()
        ExternalProject_Get_Property(gflags BINARY_DIR)
        set(GFLAGS_INCLUDE_DIRS ${BINARY_DIR}/include PARENT_SCOPE)
        set(GFLAGS_LIBRARIES ${BINARY_DIR}/lib/libgflags${POSTFIX}.a ${BINARY_DIR}/lib/libgflags_nothreads${POSTFIX}.a PARENT_SCOPE)

    elseif (dep STREQUAL "googletest")
        ExternalProject_Add(
                googletest
                URL ${PHOTON_GOOGLETEST_SOURCE}
                URL_MD5 e82199374acdfda3f425331028eb4e2a
                CMAKE_ARGS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DINSTALL_GTEST=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON
                INSTALL_COMMAND ""
        )
        ExternalProject_Get_Property(googletest SOURCE_DIR)
        ExternalProject_Get_Property(googletest BINARY_DIR)
        set(GOOGLETEST_INCLUDE_DIRS ${SOURCE_DIR}/googletest/include ${SOURCE_DIR}/googlemock/include PARENT_SCOPE)
        set(GOOGLETEST_LIBRARIES ${BINARY_DIR}/lib/libgmock.a ${BINARY_DIR}/lib/libgmock_main.a
                ${BINARY_DIR}/lib/libgtest.a ${BINARY_DIR}/lib/libgtest_main.a PARENT_SCOPE)

    elseif (dep STREQUAL "openssl")
        set(BINARY_DIR ${PROJECT_BINARY_DIR}/openssl-build)
        ExternalProject_Add(
                openssl
                URL ${PHOTON_OPENSSL_SOURCE}
                URL_MD5 bad68bb6bd9908da75e2c8dedc536b29
                BUILD_IN_SOURCE ON
                CONFIGURE_COMMAND ./config -fPIC --prefix=${BINARY_DIR} --openssldir=${BINARY_DIR} shared
                BUILD_COMMAND make -j ${NumCPU}
                INSTALL_COMMAND make install
        )
        ExternalProject_Get_Property(openssl SOURCE_DIR)
        set(OPENSSL_ROOT_DIR ${BINARY_DIR} PARENT_SCOPE)
        set(OPENSSL_INCLUDE_DIRS ${BINARY_DIR}/include PARENT_SCOPE)
        set(OPENSSL_LIBRARIES ${BINARY_DIR}/lib/libssl.a ${BINARY_DIR}/lib/libcrypto.a PARENT_SCOPE)

    elseif (dep STREQUAL "curl")
        if (${OPENSSL_ROOT_DIR} STREQUAL "")
            message(FATAL_ERROR "OPENSSL_ROOT_DIR not exist")
        endif ()
        set(BINARY_DIR ${PROJECT_BINARY_DIR}/curl-build)
        ExternalProject_Add(
                curl
                URL ${PHOTON_CURL_SOURCE}
                URL_MD5 a66270f11e3fbfad709600bbd1686704
                BUILD_IN_SOURCE ON
                CONFIGURE_COMMAND autoreconf -i && ./configure --with-ssl=${OPENSSL_ROOT_DIR}
                    --without-libssh2 --enable-static --enable-shared=no --enable-optimize
                    --disable-manual --without-libidn
                    --disable-ftp --disable-file --disable-ldap --disable-ldaps
                    --disable-rtsp --disable-dict --disable-telnet --disable-tftp
                    --disable-pop3 --disable-imap --disable-smb --disable-smtp
                    --disable-gopher --without-nghttp2 --enable-http --disable-verbose
                    --with-pic=PIC --prefix=${BINARY_DIR}
                BUILD_COMMAND make -j ${NumCPU}
                INSTALL_COMMAND make install
        )
        set(CURL_INCLUDE_DIRS ${BINARY_DIR}/include PARENT_SCOPE)
        set(CURL_LIBRARIES ${BINARY_DIR}/lib/libcurl.a PARENT_SCOPE)
    endif ()

    list(APPEND actually_built ${dep})
    set(actually_built ${actually_built} PARENT_SCOPE)
endfunction()
