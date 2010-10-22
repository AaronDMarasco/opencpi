
/*
 *  Copyright (c) Mercury Federal Systems, Inc., Arlington VA., 2009-2010
 *
 *    Mercury Federal Systems, Incorporated
 *    1901 South Bell Street
 *    Suite 402
 *    Arlington, Virginia 22202
 *    United States of America
 *    Telephone 703-413-0781
 *    FAX 703-413-0784
 *
 *  This file is part of OpenCPI (www.opencpi.org).
 *     ____                   __________   ____
 *    / __ \____  ___  ____  / ____/ __ \ /  _/ ____  _________ _
 *   / / / / __ \/ _ \/ __ \/ /   / /_/ / / /  / __ \/ ___/ __ `/
 *  / /_/ / /_/ /  __/ / / / /___/ ____/_/ / _/ /_/ / /  / /_/ /
 *  \____/ .___/\___/_/ /_/\____/_/    /___/(_)____/_/   \__, /
 *      /_/                                             /____/
 *
 *  OpenCPI is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  OpenCPI is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with OpenCPI.  If not, see <http://www.gnu.org/licenses/>.
 */


// -*- c++ -*-

#ifndef OCPI_CORBAUTIL_STRINGIFYCORBAEXCEPTION_H__
#define OCPI_CORBAUTIL_STRINGIFYCORBAEXCEPTION_H__

/**
 * \file
 * \brief Create a human-readable string from a CORBA exception.
 *
 * Revision History:
 *
 *     05/09/2005 - Frank Pilhofer
 *                  Initial version.
 *
 */

#include <string>
#include <corba.h>

namespace OCPI {
  namespace CORBAUtil {
    /**
     * \brief Miscellaneous CORBA-related utilities.
     */

    namespace Misc {

      /**
       * \brief Create a human-readable string from a CORBA exception.
       *
       * This function works best for CORBA system exceptions; for user
       * exceptions, only the name of the exception is returned.
       *
       * \param[in] ex A CORBA exception.
       * \return A human-readable string describing the exception.
       */

      std::string stringifyCorbaException (const CORBA::Exception & ex)
        throw ();

    }
  }
}

#endif
