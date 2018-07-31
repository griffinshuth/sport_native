/* -*- Mode: C++ -*- */

/*
 *Copyright:

 Copyright (C) 1996-2000 Electrotechnical Laboratory.
 Itsuki Noda, Yasuo Kuniyoshi and Hitoshi Matsubara.
 Copyright (C) 2000, 2001 RoboCup Soccer Server Maintainance Group.
 Patrick Riley, Tom Howard, Daniel Polani, Itsuki Noda,
 Mikhail Prokopenko, Jan Wendler
 Copyright (C) 2002- RoboCup Soccer Simulator Maintainance Group.

 This file is a part of SoccerServer.

 This code is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 3 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 *EndCopyright:
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "playerparam.h"

#include "utility.h"
#include <string>
#include <iostream>
#include <cerrno>
#include <cassert>

#include <sys/param.h> /* needed for htonl, htons, ... */
#include <netinet/in.h>

namespace {

inline
Int32
roundint( const double & value )
{
    return static_cast< Int32 >( value + 0.5 );
}

}

#if defined(RCSS_WIN) || defined(__CYGWIN__)
const std::string PlayerParam::CONF_DIR = "."; //"~\\.rcssserver\\";
const std::string PlayerParam::PLAYER_CONF = "player.conf";
const std::string PlayerParam::OLD_PLAYER_CONF = "rcssserver-player.conf";
#else
const std::string PlayerParam::CONF_DIR = "~/.rcssserver/";
const std::string PlayerParam::PLAYER_CONF = "player.conf";
const std::string PlayerParam::OLD_PLAYER_CONF = "~/.rcssserver-player.conf";
#endif

const int PlayerParam::DEFAULT_PLAYER_TYPES = 18; // [12.0.0] 7 -> 18
const int PlayerParam::DEFAULT_SUBS_MAX = 3;
const int PlayerParam::DEFAULT_PT_MAX = 1; // [12.0.0] 3 -> 1

const double PlayerParam::DEFAULT_PLAYER_SPEED_MAX_DELTA_MIN = 0.0;
const double PlayerParam::DEFAULT_PLAYER_SPEED_MAX_DELTA_MAX = 0.0;
const double PlayerParam::DEFAULT_STAMINA_INC_MAX_DELTA_FACTOR = 0.0;

// [13.0.0] -0.05 -> -0.1
// [12.0.0]  0.0  -> -0.05
const double PlayerParam::DEFAULT_PLAYER_DECAY_DELTA_MIN = -0.1;
// [12.0.0] 0.2 -> 0.1
const double PlayerParam::DEFAULT_PLAYER_DECAY_DELTA_MAX = 0.1;
const double PlayerParam::DEFAULT_INERTIA_MOMENT_DELTA_FACTOR = 25.0;

const double PlayerParam::DEFAULT_DASH_POWER_RATE_DELTA_MIN = 0.0;
const double PlayerParam::DEFAULT_DASH_POWER_RATE_DELTA_MAX = 0.0;
const double PlayerParam::DEFAULT_PLAYER_SIZE_DELTA_FACTOR = -100.0;

const double PlayerParam::DEFAULT_KICKABLE_MARGIN_DELTA_MIN = -0.1; // [12.0.0] 0.0 -> -0.1
const double PlayerParam::DEFAULT_KICKABLE_MARGIN_DELTA_MAX = 0.1; // [12.0.0] 0.2 -> 0.1
const double PlayerParam::DEFAULT_KICK_RAND_DELTA_FACTOR = 1.0; // [12.0.0] 0.5 -> 1.0

const double PlayerParam::DEFAULT_EXTRA_STAMINA_DELTA_MIN = 0.0;
// [13.0.0] 100.0 -> 50.0
const double PlayerParam::DEFAULT_EXTRA_STAMINA_DELTA_MAX = 50.0;
// [13.0.0] -0.002 -> -0.004
const double PlayerParam::DEFAULT_EFFORT_MAX_DELTA_FACTOR = -0.004;
// [13.0.0] -0.002 -> -0.004
const double PlayerParam::DEFAULT_EFFORT_MIN_DELTA_FACTOR = -0.004;

const int    PlayerParam::DEFAULT_RANDOM_SEED = -1; //negative means generate a new seed

// [13.0.0] -0.0005 -> -0.0012
// [12.0.0]  0      -> -0.0005
const double PlayerParam::DEFAULT_NEW_DASH_POWER_RATE_DELTA_MIN = -0.0012;
// [13.0.0] 0.0015 -> 0.0008
// [12.0.0] 0.002  -> 0.0015
const double PlayerParam::DEFAULT_NEW_DASH_POWER_RATE_DELTA_MAX = 0.0008;
// [12.0.0] -10000.0 -> -6000.0
const double PlayerParam::DEFAULT_NEW_STAMINA_INC_MAX_DELTA_FACTOR = -6000.0;

// v14
const double PlayerParam::DEFAULT_KICK_POWER_RATE_DELTA_MIN = 0.0;
const double PlayerParam::DEFAULT_KICK_POWER_RATE_DELTA_MAX = 0.0;
const double PlayerParam::DEFAULT_FOUL_DETECT_PROBABILITY_DELTA_FACTOR = 0.0;

const double PlayerParam::DEFAULT_CATCHABLE_AREA_L_STRETCH_MIN = 1.0;
const double PlayerParam::DEFAULT_CATCHABLE_AREA_L_STRETCH_MAX = 1.3;


PlayerParam &
PlayerParam::instance()
{
    static PlayerParam rval;
    return rval;
}

bool
PlayerParam::init()
{
    return true;
}

PlayerParam::PlayerParam()
{
    setDefaults();
}

PlayerParam::~PlayerParam()
{

}

void
PlayerParam::setDefaults()
{
    M_player_types = PlayerParam::DEFAULT_PLAYER_TYPES;
    M_subs_max = PlayerParam::DEFAULT_SUBS_MAX;
    M_pt_max = PlayerParam::DEFAULT_PT_MAX;

    M_allow_mult_default_type = false;

    M_player_speed_max_delta_min = PlayerParam::DEFAULT_PLAYER_SPEED_MAX_DELTA_MIN;
    M_player_speed_max_delta_max = PlayerParam::DEFAULT_PLAYER_SPEED_MAX_DELTA_MAX;
    M_stamina_inc_max_delta_factor = PlayerParam::DEFAULT_STAMINA_INC_MAX_DELTA_FACTOR;

    M_player_decay_delta_min = PlayerParam::DEFAULT_PLAYER_DECAY_DELTA_MIN;
    M_player_decay_delta_max = PlayerParam::DEFAULT_PLAYER_DECAY_DELTA_MAX;
    M_inertia_moment_delta_factor = PlayerParam::DEFAULT_INERTIA_MOMENT_DELTA_FACTOR;

    M_dash_power_rate_delta_min = PlayerParam::DEFAULT_DASH_POWER_RATE_DELTA_MIN;
    M_dash_power_rate_delta_max = PlayerParam::DEFAULT_DASH_POWER_RATE_DELTA_MAX;
    M_player_size_delta_factor = PlayerParam::DEFAULT_PLAYER_SIZE_DELTA_FACTOR;

    M_kickable_margin_delta_min = PlayerParam::DEFAULT_KICKABLE_MARGIN_DELTA_MIN;
    M_kickable_margin_delta_max = PlayerParam::DEFAULT_KICKABLE_MARGIN_DELTA_MAX;
    M_kick_rand_delta_factor = PlayerParam::DEFAULT_KICK_RAND_DELTA_FACTOR;

    M_extra_stamina_delta_min = PlayerParam::DEFAULT_EXTRA_STAMINA_DELTA_MIN;
    M_extra_stamina_delta_max = PlayerParam::DEFAULT_EXTRA_STAMINA_DELTA_MAX;
    M_effort_max_delta_factor = PlayerParam::DEFAULT_EFFORT_MAX_DELTA_FACTOR;
    M_effort_min_delta_factor = PlayerParam::DEFAULT_EFFORT_MIN_DELTA_FACTOR;

    M_random_seed = PlayerParam::DEFAULT_RANDOM_SEED;

    M_new_dash_power_rate_delta_min = PlayerParam::DEFAULT_NEW_DASH_POWER_RATE_DELTA_MIN;
    M_new_dash_power_rate_delta_max = PlayerParam::DEFAULT_NEW_DASH_POWER_RATE_DELTA_MAX;
    M_new_stamina_inc_max_delta_factor = PlayerParam::DEFAULT_NEW_STAMINA_INC_MAX_DELTA_FACTOR;

    M_kick_power_rate_delta_min = PlayerParam::DEFAULT_KICK_POWER_RATE_DELTA_MIN;
    M_kick_power_rate_delta_max = PlayerParam::DEFAULT_KICK_POWER_RATE_DELTA_MAX;
    M_foul_detect_probability_delta_factor = PlayerParam::DEFAULT_FOUL_DETECT_PROBABILITY_DELTA_FACTOR;


    //M_allow_default_goalie = true;
    M_catchable_area_l_stretch_min = PlayerParam::DEFAULT_CATCHABLE_AREA_L_STRETCH_MIN;
    M_catchable_area_l_stretch_max = PlayerParam::DEFAULT_CATCHABLE_AREA_L_STRETCH_MAX;
}

player_params_t
PlayerParam::convertToStruct() const
{
    player_params_t tmp;

    tmp.player_types = htons( static_cast< Int16 >( playerTypes() ) );
    tmp.subs_max = htons( static_cast< Int16 >( subsMax() ) );
    tmp.pt_max = htons( static_cast< Int16 >( ptMax() ) );

    tmp.player_speed_max_delta_min = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * playerSpeedMaxDeltaMin() ) ) ) );
    tmp.player_speed_max_delta_max = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * playerSpeedMaxDeltaMax() ) ) ) );
    tmp.stamina_inc_max_delta_factor = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * staminaIncMaxDeltaFactor() ) ) ) );

    tmp.player_decay_delta_min = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * playerDecayDeltaMin() ) ) ) );
    tmp.player_decay_delta_max = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * playerDecayDeltaMax() ) ) ) );
    tmp.inertia_moment_delta_factor = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * inertiaMomentDeltaFactor() ) ) ) );

    tmp.dash_power_rate_delta_min = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * dashPowerRateDeltaMin() ) ) ) );
    tmp.dash_power_rate_delta_max = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * dashPowerRateDeltaMax() ) ) ) );
    tmp.player_size_delta_factor = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * playerSizeDeltaFactor() ) ) ) );

    tmp.kickable_margin_delta_min = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * kickableMarginDeltaMin() ) ) ) );
    tmp.kickable_margin_delta_max = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * kickableMarginDeltaMax() ) ) ) );
    tmp.kick_rand_delta_factor = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * kickRandDeltaFactor() ) ) ) );

    tmp.extra_stamina_delta_min = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * extraStaminaDeltaMin() ) ) ) );
    tmp.extra_stamina_delta_max = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * extraStaminaDeltaMax() ) ) ) );
    tmp.effort_max_delta_factor = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * effortMaxDeltaFactor() ) ) ) );
    tmp.effort_min_delta_factor = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * effortMinDeltaFactor() ) ) ) );
    tmp.random_seed = htonl( static_cast< Int32 >( randomSeed() ) );

    tmp.new_dash_power_rate_delta_min = htonl( static_cast< Int32 >( roundint(( SHOWINFO_SCALE2 * newDashPowerRateDeltaMin() ) ) ) );
    tmp.new_dash_power_rate_delta_max = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * newDashPowerRateDeltaMax() ) ) ) );
    tmp.new_stamina_inc_max_delta_factor = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * newStaminaIncMaxDeltaFactor() ) ) ) );

    tmp.kick_power_rate_delta_min = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * kickPowerRateDeltaMin() ) ) ) );
    tmp.kick_power_rate_delta_max = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * kickPowerRateDeltaMax() ) ) ) );
    tmp.foul_detect_probability_delta_factor = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * foulDetectProbabilityDeltaFactor() ) ) ) );

    tmp.catchable_area_l_stretch_min = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * catchAreaLengthStretchMin() ) ) ) );
    tmp.catchable_area_l_stretch_max = htonl( static_cast< Int32 >( roundint( ( SHOWINFO_SCALE2 * catchAreaLengthStretchMax() ) ) ) );

    tmp.allow_mult_default_type = htons( static_cast< Int16 >( allowMultDefaultType() ) );
    //tmp.allow_default_goalie = htons( static_cast< Int16 >( allowDefaultGoalie() ) );

    return tmp;
}
