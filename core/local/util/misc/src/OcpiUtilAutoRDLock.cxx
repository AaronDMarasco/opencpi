
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

#include <OcpiUtilAutoRDLock.h>
#include <OcpiOsAssert.h>
#include <OcpiOsRWLock.h>

OCPI::Util::AutoRDLock::AutoRDLock (OCPI::OS::RWLock & rwlock, bool locked)
  throw (std::string)
  : m_locked (locked),
    m_rwlock (rwlock)
{
  if (locked) {
    m_rwlock.rdLock ();
  }
}

OCPI::Util::AutoRDLock::~AutoRDLock ()
  throw ()
{
  if (m_locked) {
    m_rwlock.rdUnlock ();
  }
}

void
OCPI::Util::AutoRDLock::lock ()
  throw (std::string)
{
  ocpiAssert (!m_locked);
  m_rwlock.rdLock ();
  m_locked = true;
}

bool
OCPI::Util::AutoRDLock::trylock ()
  throw (std::string)
{
  ocpiAssert (!m_locked);
  return (m_locked = m_rwlock.rdTrylock ());
}

void
OCPI::Util::AutoRDLock::unlock ()
  throw (std::string)
{
  ocpiAssert (m_locked);
  m_rwlock.rdUnlock ();
  m_locked = false;
}
