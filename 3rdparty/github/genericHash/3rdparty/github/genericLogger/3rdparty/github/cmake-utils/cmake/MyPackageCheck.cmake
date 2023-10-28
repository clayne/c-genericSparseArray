MACRO (MYPACKAGECHECK name)

  #
  # C.f https://stackoverflow.com/questions/57099207/simple-way-to-get-all-paths-to-interface-link-libraries-of-an-imported-target-re
  #
  macro(getAllLinkedLibrariesDirectories iTarget iReturnValue)
    if(TARGET ${iTarget})
      get_target_property(linkedLibrairies ${iTarget} LINK_LIBRARIES)
      IF (MYPACKAGE_DEBUG)
        MESSAGE(STATUS "[${PROJECT_NAME}-CHECK-DEBUG] ${iTarget} LINK_LIBRARIES property: ${linkedLibrairies}")
      ENDIF ()
      FOREACH(linkedLibrary ${linkedLibrairies})
        if(TARGET ${linkedLibrary})
          get_target_property(linkedLibraryDirectory ${linkedLibrary} LIBRARY_OUTPUT_DIRECTORY)
          IF (MYPACKAGE_DEBUG)
            MESSAGE(STATUS "[${PROJECT_NAME}-CHECK-DEBUG] ${linkedLibrary} LIBRARY_OUTPUT_DIRECTORY property: ${linkedLibraryDirectory}")
          ENDIF ()
          if(NOT ${linkedLibraryDirectory} IN_LIST ${iReturnValue})
            list(APPEND ${iReturnValue} ${linkedLibraryDirectory})
          endif()
		  getAllLinkedLibrariesDirectories(${linkedLibrary} ${iReturnValue})
        endif()
      ENDFOREACH()
    endif()
  endmacro()

  IF ("${CMAKE_HOST_SYSTEM}" MATCHES ".*Windows.*")
    SET (SEP "\\;")
  ELSE ()
    SET (SEP ":")
  ENDIF ()

  GET_PROPERTY(_test_path_set GLOBAL PROPERTY MYPACKAGE_TEST_PATH SET)
  IF (${_test_path_set})
    GET_PROPERTY(_test_path GLOBAL PROPERTY MYPACKAGE_TEST_PATH)
  ELSE ()
    SET (_test_path $ENV{PATH})
    IF ("${CMAKE_HOST_SYSTEM}" MATCHES ".*Windows.*")
      STRING(REGEX REPLACE "/" "\\\\"  _test_path "${_test_path}")
    ELSE ()
      STRING(REGEX REPLACE " " "\\\\ "  _test_path "${_test_path}")
    ENDIF ()
    IF (MYPACKAGE_DEBUG)
      MESSAGE(STATUS "[${PROJECT_NAME}-CHECK-DEBUG] Initializing TEST_PATH with PATH")
    ENDIF ()
    SET_PROPERTY(GLOBAL PROPERTY MYPACKAGE_TEST_PATH ${_test_path})
  ENDIF ()

  GET_PROPERTY(_targets_for_test_set GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${PROJECT_NAME}_TARGETS_FOR_TEST SET)
  IF (_targets_for_test_set)
    GET_PROPERTY(_targets_for_test GLOBAL PROPERTY MYPACKAGE_DEPENDENCY_${PROJECT_NAME}_TARGETS_FOR_TEST)
    FOREACH (_target ${_targets_for_test})
      IF (NOT ("${_test_path}" STREQUAL ""))
        SET (_test_path "\$<TARGET_FILE_DIR:${_target}>${SEP}${_test_path}")
      ELSE ()
        SET (_test_path "\$<TARGET_FILE_DIR:${_target}>")
      ENDIF ()
    ENDFOREACH ()
  ENDIF ()

  IF (NOT ("x${TARGET_TEST_CMAKE_COMMAND}" STREQUAL "x"))
    GET_FILENAME_COMPONENT(_target_test_cmake_command ${TARGET_TEST_CMAKE_COMMAND} ABSOLUTE)
  ELSE ()
    SET (_target_test_cmake_command "")
  ENDIF ()
  FOREACH (_name ${name} ${name}_static)
    IF (MYPACKAGE_DEBUG)
      MESSAGE (STATUS "[${PROJECT_NAME}-CHECK-DEBUG] Adding test ${_name}")
    ENDIF ()

    getAllLinkedLibrariesDirectories(${_name} _allLinkedLibrariesDirectories)
    IF (MYPACKAGE_DEBUG)
      MESSAGE(STATUS "[${PROJECT_NAME}-CHECK-DEBUG] ${_name} linked libraries directories: ${_allLinkedLibrariesDirectories}")
    ENDIF ()

    set(_name_test_path ${_test_path})
    FOREACH (_linkedLibraryDirectory ${_allLinkedLibrariesDirectories})
      IF ("${CMAKE_HOST_SYSTEM}" MATCHES ".*Windows.*")
        STRING(REGEX REPLACE "/" "\\\\"  _linkedLibraryDirectory "${_linkedLibraryDirectory}")
      ELSE ()
        STRING(REGEX REPLACE " " "\\\\ "  _linkedLibraryDirectory "${_linkedLibraryDirectory}")
      ENDIF ()
      IF (MYPACKAGE_DEBUG)
        MESSAGE(STATUS "[${PROJECT_NAME}-CHECK-DEBUG] Adding ${_linkedLibraryDirectory} to TEST_PATH")
      ENDIF ()
      IF ("${CMAKE_HOST_SYSTEM}" MATCHES ".*Windows.*")
        SET(_name_test_path "${_name_test_path};${_linkedLibraryDirectory}")
      ELSE ()
        SET(_name_test_path "${_name_test_path}:${_linkedLibraryDirectory}")
      ENDIF ()
    ENDFOREACH ()

    ADD_TEST (NAME ${_name}
      COMMAND ${CMAKE_COMMAND} -E env "PATH=${_name_test_path}" ${_target_test_cmake_command} $<TARGET_FILE:${_name}> ${ARGN}
      WORKING_DIRECTORY ${LIBRARY_OUTPUT_PATH})
    ADD_DEPENDENCIES(check ${_name})
  ENDFOREACH ()

ENDMACRO()
