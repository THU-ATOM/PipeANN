# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.

set(CMAKE_CXX_STANDARD 17)

if(MSVC)
	add_subdirectory(dll)
else()
	#file(GLOB CPP_SOURCES *.cpp)
	file(GLOB CPP_SOURCES *.cpp v2/*.cpp)
	add_library(${PROJECT_NAME} ${CPP_SOURCES})
	# add_library(${PROJECT_NAME}_s STATIC ${CPP_SOURCES})
	target_link_libraries(${PROJECT_NAME} -l:libaio.so.1)
	# target_link_libraries(${PROJECT_NAME}_s -l:libaio.so.1)
endif()
install()
