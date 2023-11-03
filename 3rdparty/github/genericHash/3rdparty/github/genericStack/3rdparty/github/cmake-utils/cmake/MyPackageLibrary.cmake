MACRO (MYPACKAGELIBRARY config_in config_out)
  #
  # Call for the configuration
  #
  MYPACKAGECONFIG(${config_in} ${config_out})

  IF (MYPACKAGE_DEBUG)
    FOREACH (_source ${ARGN})
      MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] Source: ${_source}")
    ENDFOREACH ()
  ENDIF ()
  #
  # Shared library
  #
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] ADD_LIBRARY (${PROJECT_NAME}_shared SHARED ${ARGN}>")
  ENDIF ()
  ADD_LIBRARY (${PROJECT_NAME}_shared SHARED ${ARGN})
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] TARGET_COMPILE_DEFINITIONS(${PROJECT_NAME}_shared PRIVATE -D${PROJECT_NAME}_EXPORTS)")
  ENDIF ()
  TARGET_COMPILE_DEFINITIONS(${PROJECT_NAME}_shared PRIVATE -D${PROJECT_NAME}_EXPORTS)
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] SET_TARGET_PROPERTIES(${PROJECT_NAME}_shared PROPERTIES VERSION ${${PROJECT_NAME}_VERSION} SOVERSION ${${PROJECT_NAME}_VERSION_MAJOR} OUTPUT_NAME ${PROJECT_NAME}))")
  ENDIF ()
  SET_TARGET_PROPERTIES(${PROJECT_NAME}_shared PROPERTIES VERSION ${${PROJECT_NAME}_VERSION} SOVERSION ${${PROJECT_NAME}_VERSION_MAJOR} OUTPUT_NAME ${PROJECT_NAME})
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] TARGET_LINK_LIBRARIES(${PROJECT_NAME}_shared PUBLIC ${PROJECT_NAME}_iface)")
  ENDIF ()
  TARGET_LINK_LIBRARIES(${PROJECT_NAME}_shared PUBLIC ${PROJECT_NAME}_iface)
  #
  # Static library
  #
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] ADD_LIBRARY (${PROJECT_NAME}_static STATIC ${ARGN}>")
  ENDIF ()
  ADD_LIBRARY (${PROJECT_NAME}_static STATIC ${ARGN})
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] TARGET_COMPILE_DEFINITIONS(${PROJECT_NAME}_static PUBLIC -D${PROJECT_NAME}_STATIC)")
  ENDIF ()
  TARGET_COMPILE_DEFINITIONS(${PROJECT_NAME}_static PUBLIC -D${PROJECT_NAME}_STATIC)
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] SET_TARGET_PROPERTIES(${PROJECT_NAME}_static PROPERTIES OUTPUT_NAME ${PROJECT_NAME}_static)")
  ENDIF ()
  SET_TARGET_PROPERTIES(${PROJECT_NAME}_static PROPERTIES OUTPUT_NAME ${PROJECT_NAME}_static)
  IF (MYPACKAGE_DEBUG)
    MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] TARGET_LINK_LIBRARIES(${PROJECT_NAME}_static INTERFACE ${PROJECT_NAME}_iface)")
  ENDIF ()
  TARGET_LINK_LIBRARIES(${PROJECT_NAME}_static PUBLIC ${PROJECT_NAME}_iface)
  #
  # ... Tracing
  #
  STRING (TOUPPER ${PROJECT_NAME} _PROJECTNAME)
  IF (NTRACE)
    FOREACH (_target ${PROJECT_NAME}_shared ${PROJECT_NAME}_static)
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] Setting PRIVATE -D${_PROJECTNAME}_NTRACE on ${_target}")
      ENDIF ()
      TARGET_COMPILE_DEFINITIONS(${_target} PRIVATE -D${_PROJECTNAME}_NTRACE)
    ENDFOREACH ()
  ENDIF ()
  #
  # ... Version information
  #
  FOREACH (_target ${PROJECT_NAME}_shared ${PROJECT_NAME}_static)
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] Setting PRIVATE version macros on ${_target}")
    ENDIF ()
    TARGET_COMPILE_DEFINITIONS(${_target}
      PRIVATE -D${_PROJECTNAME}_VERSION_MAJOR=${${PROJECT_NAME}_VERSION_MAJOR}
      PRIVATE -D${_PROJECTNAME}_VERSION_MINOR=${${PROJECT_NAME}_VERSION_MINOR}
      PRIVATE -D${_PROJECTNAME}_VERSION_PATCH=${${PROJECT_NAME}_VERSION_PATCH}
      PRIVATE -D${_PROJECTNAME}_VERSION="${${PROJECT_NAME}_VERSION}"
    )
  ENDFOREACH ()
  #
  # We always enable C99 when available
  #
  FOREACH (_target ${PROJECT_NAME}_shared ${PROJECT_NAME}_static)
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] Setting PROPERTY C_STANDARD 99 on ${_target}")
    ENDIF ()
    SET_PROPERTY(TARGET ${_target} PROPERTY C_STANDARD 99)
  ENDFOREACH ()
  #
  # OS Specifics
  #
  IF (CMAKE_SYSTEM_NAME MATCHES "NetBSD")
    #
    # On NetBSD, enable this platform features. This makes sure we always have "long long" btw.
    #
    FOREACH (_target ${PROJECT_NAME}_shared ${PROJECT_NAME}_static)
      IF (MYPACKAGE_DEBUG)
        MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] Setting PUBLIC -D_NETBSD_SOURCE=1 on ${_target}")
      ENDIF ()
      TARGET_COMPILE_DEFINITIONS (${_target} PUBLIC -D_NETBSD_SOURCE=1)
    ENDFOREACH ()
  ENDIF ()
  #
  # Call for config and export headers
  #
  MYPACKAGEEXPORT()
  FOREACH (_target ${PROJECT_NAME}_shared ${PROJECT_NAME}_static)
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] Adding ${PROJECT_NAME}_export ${PROJECT_NAME}_config dependencies to ${_target}")
    ENDIF ()
    ADD_DEPENDENCIES(${_target} ${PROJECT_NAME}_export ${PROJECT_NAME}_config)
  ENDFOREACH ()
  #
  # For static library we want to debug information within the lib
  # For shared library we want to install the pdb file if it exists
  #
  IF (MSVC)
    TARGET_COMPILE_OPTIONS(${PROJECT_NAME}_static PRIVATE /Z7)
    INSTALL(FILES $<TARGET_PDB_FILE:${PROJECT_NAME}_shared> DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT LibraryComponent OPTIONAL)
  ENDIF ()
  #
  # We make sure that the directory where is ${config_out} is public
  #
  GET_FILENAME_COMPONENT(_config_out_dir ${config_out} DIRECTORY)
  FOREACH (_target ${PROJECT_NAME}_shared ${PROJECT_NAME}_static)
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-LIBRARY-DEBUG] TARGET_INCLUDE_DIRECTORIES(${_target} PRIVATE ${_config_out_dir})")
    ENDIF ()
    TARGET_INCLUDE_DIRECTORIES(${_target} PRIVATE ${_config_out_dir})
  ENDFOREACH ()
  #
  # Installs
  #
  INSTALL (TARGETS ${PROJECT_NAME}_shared ${PROJECT_NAME}_static
    EXPORT ${PROJECT_NAME}-targets
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} COMPONENT HeaderComponent
    RUNTIME  DESTINATION ${CMAKE_INSTALL_BINDIR}     COMPONENT LibraryComponent
    LIBRARY  DESTINATION ${CMAKE_INSTALL_LIBDIR}     COMPONENT LibraryComponent
    ARCHIVE  DESTINATION ${CMAKE_INSTALL_LIBDIR}     COMPONENT LibraryComponent
  )
  #
  # Inform CPack
  #
  SET (${PROJECT_NAME}_HAVE_LIBRARYCOMPONENT TRUE CACHE INTERNAL "Have LibraryComponent" FORCE)
ENDMACRO()
