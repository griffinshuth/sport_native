/* -*- Mode: c++ -*- */

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

#include "serverparam.h"

#include "playerparam.h"

#include "utility.h"
#include <algorithm>
#include <string>
#include <iostream>
#include <sstream>
#include <cstring>
#include <cstdlib>

#include <sys/param.h> /* needed for htonl, htons, ... */
#include <netinet/in.h>

namespace {

//! Lowest Common Multiple
int
lcm( int a,
     int b )
{
    int tmp = 0, idx = 0, larger = std::max( a, b );
    do
    {
        ++idx;
        tmp = larger * idx;
    }
    while ( tmp % a != 0 || tmp % b != 0 );
    return tmp;
}

}


bool ServerParam::S_in_init = false;
const int ServerParam::DEFAULT_PORT_NUMBER = 6000;
const int ServerParam::COACH_PORT_NUMBER = 6001;
const int ServerParam::OLCOACH_PORT_NUMBER = 6002;

const int ServerParam::SIMULATOR_STEP_INTERVAL_MSEC = 100;
const int ServerParam::UDP_RECV_STEP_INTERVAL_MSEC = 10;
const int ServerParam::UDP_SEND_STEP_INTERVAL_MSEC = 150;
const int ServerParam::SENSE_BODY_INTERVAL_MSEC = 100;
const int ServerParam::SEND_VISUALINFO_INTERVAL_MSEC = 100;

const int ServerParam::HALF_TIME = 300;
const int ServerParam::DROP_TIME = 100;

const double ServerParam::PITCH_LENGTH = 105.0;
const double ServerParam::PITCH_WIDTH = 68.0;
const double ServerParam::PITCH_MARGIN = 5.0;
const double ServerParam::CENTER_CIRCLE_R = 9.15;
const double ServerParam::PENALTY_AREA_LENGTH = 16.5;
const double ServerParam::PENALTY_AREA_WIDTH = 40.32;
const double ServerParam::GOAL_AREA_LENGTH = 5.5;
const double ServerParam::GOAL_AREA_WIDTH = 18.32;
const double ServerParam::GOAL_WIDTH = 14.02;
const double ServerParam::GOAL_DEPTH = 2.44;
const double ServerParam::PENALTY_SPOT_DIST = 11.0;
const double ServerParam::CORNER_ARC_R = 1.0;
const double ServerParam::KICK_OFF_CLEAR_DISTANCE = CENTER_CIRCLE_R;

const double ServerParam::CORNER_KICK_MARGIN = 1.0;

const double ServerParam::KEEPAWAY_LENGTH = 20.0;
const double ServerParam::KEEPAWAY_WIDTH = 20.0;

const double ServerParam::BALL_SIZE = 0.085;
const double ServerParam::BALL_DECAY = 0.94;
const double ServerParam::BALL_RAND = 0.05;
const double ServerParam::BALL_WEIGHT = 0.2;
const double ServerParam::BALL_T_VEL = 0.001;
const double ServerParam::BALL_SPEED_MAX = 3.0; // [12.0.0] 2.7 -> 3.0;
const double ServerParam::BALL_ACCEL_MAX = 2.7;

const double ServerParam::PLAYER_SIZE = 0.3;
const double ServerParam::PLAYER_WIDGET_SIZE = 1.0;
const double ServerParam::PLAYER_DECAY = 0.4;
const double ServerParam::PLAYER_RAND = 0.1;
const double ServerParam::PLAYER_WEIGHT = 60.0;
const double ServerParam::PLAYER_SPEED_MAX = 1.05; // [13.0.0] 1.2 -> 1.05
// th 6.3.00
const double ServerParam::PLAYER_ACCEL_MAX = 1.0;
//
const double ServerParam::IMPARAM = 5.0;

const double ServerParam::STAMINA_MAX = 8000.0; // [13.0.0] 4000.0 -> 8000.0
const double ServerParam::STAMINA_INC_MAX = 45.0;
const double ServerParam::RECOVERY_DEC_THR = 0.3;
const double ServerParam::RECOVERY_DEC = 0.002;
const double ServerParam::RECOVERY_MIN = 0.5;
const double ServerParam::EFFORT_DEC_THR = 0.3;
const double ServerParam::EFFORT_DEC = 0.005;
const double ServerParam::EFFORT_MIN = 0.6;
const double ServerParam::EFFORT_INC_THR = 0.6;
const double ServerParam::EFFORT_INC = 0.01;

const double ServerParam::KICK_RAND = 0.1; // [12.0.0] 0.0 -> 0.1
const double ServerParam::PRAND_FACTOR_L = 1.0;
const double ServerParam::PRAND_FACTOR_R = 1.0;
const double ServerParam::KICK_RAND_FACTOR_L = 1.0;
const double ServerParam::KICK_RAND_FACTOR_R = 1.0;


const double ServerParam::GOALIE_CATCHABLE_POSSIBILITY = 1.0;
const double ServerParam::GOALIE_CATCHABLE_AREA_LENGTH = 1.2; // [12.0.0] 2.0 -> 1.2
const double ServerParam::GOALIE_CATCHABLE_AREA_WIDTH = 1.0;
const int ServerParam::GOALIE_CATCH_BAN_CYCLE = 5;
const int ServerParam::GOALIE_MAX_MOVES = 2;

const double ServerParam::VISIBLE_ANGLE = 90.0;
const double ServerParam::VISIBLE_DISTANCE = 3.0;
const double ServerParam::AUDIO_CUT_OFF_DIST = 50.0;

const double ServerParam::DASHPOWERRATE = 0.006;
const double ServerParam::KICKPOWERRATE = 0.027;
const double ServerParam::MAXPOWER = 100.0;
const double ServerParam::MINPOWER = -100.0;

const double ServerParam::KICKABLE_MARGIN = 0.7;
const double ServerParam::CONTROL_RADIUS = 2.0;

const double ServerParam::DIST_QSTEP = 0.1;
const double ServerParam::LAND_QSTEP = 0.01;
const double ServerParam::DIR_QSTEP = 0.1;

const double ServerParam::MAXMOMENT = 180;
const double ServerParam::MINMOMENT = -180;

const double ServerParam::MAX_NECK_MOMENT = 180;
const double ServerParam::MIN_NECK_MOMENT = -180;

const double ServerParam::MAX_NECK_ANGLE = 90;
const double ServerParam::MIN_NECK_ANGLE = -90;

const int ServerParam::DEF_SAY_COACH_MSG_SIZE = 128;
const int ServerParam::DEF_SAY_COACH_CNT_MAX = 128;

const double ServerParam::WIND_DIR = 0.0;
const double ServerParam::WIND_FORCE = 0.0;
const double ServerParam::WIND_RAND = 0.0;
const double ServerParam::WIND_WEIGHT = 10000.0;

const double ServerParam::OFFSIDE_ACTIVE_AREA_SIZE = 2.5;
const double ServerParam::OFFSIDE_KICK_MARGIN = 9.15;

#if defined(RCSS_WIN) || defined(__CYGWIN__)
const std::string ServerParam::LANDMARK_FILE = "rcssserver-landmark.xml";
const std::string ServerParam::CONF_DIR = ".";  //"~\\.rcssserver\\";
const std::string ServerParam::SERVER_CONF = "server.conf";
const std::string ServerParam::OLD_SERVER_CONF = "rcssserver-server.conf";
#else
const std::string ServerParam::LANDMARK_FILE = "~/.rcssserver-landmark.xml";
const std::string ServerParam::CONF_DIR = "~/.rcssserver/";
const std::string ServerParam::SERVER_CONF = "server.conf";
const std::string ServerParam::OLD_SERVER_CONF = "~/.rcssserver-server.conf";
#endif

const int ServerParam::SEND_COMMS = false;

const int ServerParam::TEXT_LOGGING = true;
const int ServerParam::GAME_LOGGING = true;
const int ServerParam::GAME_LOG_VERSION = DEFAULT_REC_VERSION;
#ifdef RCSS_WIN
const std::string ServerParam::TEXT_LOG_DIR = ".\\";
const std::string ServerParam::GAME_LOG_DIR = ".\\";
#else
const std::string ServerParam::TEXT_LOG_DIR = "./";
const std::string ServerParam::GAME_LOG_DIR = "./";
#endif
const std::string ServerParam::TEXT_LOG_FIXED_NAME = "rcssserver";
const std::string ServerParam::GAME_LOG_FIXED_NAME = "rcssserver";
const int ServerParam::TEXT_LOG_FIXED = false;
const int ServerParam::GAME_LOG_FIXED = false;
const int ServerParam::TEXT_LOG_DATED = true;
const int ServerParam::GAME_LOG_DATED = true;
const std::string ServerParam::LOG_DATE_FORMAT = "%Y%m%d%H%M%S-";
const int ServerParam::LOG_TIMES = false;
const int ServerParam::RECORD_MESSAGES = false;
const int ServerParam::TEXT_LOG_COMPRESSION = 0;
const int ServerParam::GAME_LOG_COMPRESSION = 0;
const bool ServerParam::PROFILE = false;

const int ServerParam::KAWAY_LOGGING = true;
#ifdef RCSS_WIN
const std::string ServerParam::KAWAY_LOG_DIR = ".\\";
#else
const std::string ServerParam::KAWAY_LOG_DIR = "./";
#endif
const std::string ServerParam::KAWAY_LOG_FIXED_NAME = "rcssserver";
const int ServerParam::KAWAY_LOG_FIXED = false;
const int ServerParam::KAWAY_LOG_DATED = true;

const int ServerParam::KAWAY_START = -1;

const int ServerParam::POINT_TO_BAN = 5;
const int ServerParam::POINT_TO_DURATION= 20;
const unsigned int ServerParam::SAY_MSG_SIZE = 10;
const unsigned int ServerParam::HEAR_MAX = 1;
const unsigned int ServerParam::HEAR_INC = 1;
const unsigned int ServerParam::HEAR_DECAY = 1;

const double ServerParam::TACKLE_DIST = 2.0;
const double ServerParam::TACKLE_BACK_DIST = 0.0; // [12.0.0] 0.5 -> 0.0
const double ServerParam::TACKLE_WIDTH = 1.25; // [12.0.0] 1.0 -> 1.25
const double ServerParam::TACKLE_EXPONENT = 6.0;
const unsigned int ServerParam::TACKLE_CYCLES = 10;
const double ServerParam::TACKLE_POWER_RATE = 0.027;

const int ServerParam::NR_NORMAL_HALFS = 2;
const int ServerParam::NR_EXTRA_HALFS = 2;
const bool ServerParam::PENALTY_SHOOT_OUTS = true;

const int    ServerParam::PEN_BEFORE_SETUP_WAIT = 10; // [13.2.0] 30 -> 10
const int    ServerParam::PEN_SETUP_WAIT = 70; // [13.2.0] 100 -> 70
const int    ServerParam::PEN_READY_WAIT = 10; // [13.2.0] 50 -> 10
const int    ServerParam::PEN_TAKEN_WAIT = 150; // [13.2.0] 200 -> 150
const int    ServerParam::PEN_NR_KICKS = 5;
const int    ServerParam::PEN_MAX_EXTRA_KICKS = 5; // [13.2.0] 10 -> 5
const double ServerParam::PEN_DIST_X = 42.5;
const bool   ServerParam::PEN_RANDOM_WINNER = false;
const double ServerParam::PEN_MAX_GOALIE_DIST_X = 14;
const bool   ServerParam::PEN_ALLOW_MULT_KICKS = true;
const bool   ServerParam::PEN_COACH_MOVES_PLAYERS = true;


const unsigned int ServerParam::FREEFORM_WAIT_PERIOD = 600;
const unsigned int ServerParam::FREEFORM_SEND_PERIOD = 20;

const bool ServerParam::FREE_KICK_FAULTS = true;
const bool ServerParam::BACK_PASSES = true;

const bool ServerParam::PROPER_GOAL_KICKS = false;
const double ServerParam::STOPPED_BALL_VEL = 0.01;
const int ServerParam::MAX_GOAL_KICKS = 3;

const int ServerParam::CLANG_DEL_WIN = 1;
const int ServerParam::CLANG_RULE_WIN = 1;

const bool ServerParam::S_AUTO_MODE = false;
const int ServerParam::S_KICK_OFF_WAIT = 100;
const int ServerParam::S_CONNECT_WAIT = 300;
const int ServerParam::S_GAME_OVER_WAIT = 100;

const std::string ServerParam::S_TEAM_L_START = "";
const std::string ServerParam::S_TEAM_R_START = "";

// 11.0.0
const double ServerParam::BALL_STUCK_AREA = 3.0;

// 12.0.0
const double ServerParam::MAX_TACKLE_POWER = 100.0;
const double ServerParam::MAX_BACK_TACKLE_POWER = 0.0; // [13.0.0] 50.0 -> 0.0
const double ServerParam::PLAYER_SPEED_MAX_MIN = 0.75; // [13.0.0] 0.8 -> 0.75
const double ServerParam::EXTRA_STAMINA = 50.0; // [13.0.0] 0.0 -> 50.0
const int ServerParam::SYNCH_SEE_OFFSET = 0; // [13.2.0] 30 -> 0;

// 12.1.3
const int ServerParam::EXTRA_HALF_TIME = 100; // [13.0.0] 300 -> 100

// 13.0.0
const double ServerParam::STAMINA_CAPACITY = 130600.0; // [14.0.0] 148600.0 -> 130600.0
const double ServerParam::MAX_DASH_ANGLE = +180.0;
const double ServerParam::MIN_DASH_ANGLE = -180.0;
const double ServerParam::DASH_ANGLE_STEP = 45.0; // [14.0.0] 90.0 -> 45.0
const double ServerParam::SIDE_DASH_RATE = 0.4; // [14.0.0] 0.25 -> 0.4
const double ServerParam::BACK_DASH_RATE = 0.6; // [14.0.0] 0.5 -> 0.6
const double ServerParam::MAX_DASH_POWER = +100.0;
const double ServerParam::MIN_DASH_POWER = -100.0;

// 14.0.0
const double ServerParam::TACKLE_RAND_FACTOR = 2.0;
const double ServerParam::FOUL_DETECT_PROBABILITY = 0.5;
const double ServerParam::FOUL_EXPONENT = 10.0;
const int ServerParam::FOUL_CYCLES = 5;
const bool ServerParam::GOLDEN_GOAL = false; // [15.0.0] true -> false

// 15.0.0
const double ServerParam::RED_CARD_PROBABILITY = 0.0;

// XXX
const double ServerParam::LONG_KICK_POWER_FACTOR = 2.0;
const int ServerParam::LONG_KICK_DELAY = 2;


ServerParam &
ServerParam::instance()
{
    static ServerParam rval;
    return rval;
}

bool
ServerParam::init()
{
    S_in_init = true;
    instance();
    S_in_init = false;

    if ( ! PlayerParam::init() )
    {
        instance().clear();
        return false;
    }
    instance().setSlowDownFactor();
    return true;
}

void
ServerParam::setSlowDownFactor()
{
    M_slow_down_factor = std::max( 1, M_slow_down_factor );

    M_half_time = static_cast< int >( M_raw_half_time * getHalfTimeScaler() + 0.5 );
    M_extra_half_time = static_cast< int >( M_raw_extra_half_time * getHalfTimeScaler() + 0.5 );

    M_simulator_step *= M_slow_down_factor;
    M_sense_body_step *= M_slow_down_factor;
    M_send_vi_step *= M_slow_down_factor;
    M_send_step *= M_slow_down_factor;
    M_synch_offset *= M_slow_down_factor;
    M_synch_see_offset *= M_slow_down_factor;

    M_lcm_step = lcm( M_simulator_step,
                      lcm( M_send_step,
                           lcm( M_recv_step,
                                lcm( M_sense_body_step,
                                     lcm( M_send_vi_step,
                                          lcm( std::max( M_synch_see_offset, 1 ),
                                               ( M_synch_mode ? M_synch_offset : 1 ) ) ) ) ) ) );
}

ServerParam::ServerParam()
{
    setDefaults();
    if ( ! ServerParam::S_in_init )
    {
        std::cerr << "Warning: ServerParam is being used before it has been initialised."
                  << std::endl;
    }
}

ServerParam::~ServerParam()
{
   
}

void
ServerParam::setCTLRadius( double value )
{
    M_control_radius_width -= M_control_radius;
    M_control_radius = value;
    M_control_radius_width += M_control_radius;
}

void
ServerParam::setKickMargin( double value )
{
    M_kickable_area -= M_kickable_margin;
    M_kickable_margin = value;
    M_kickable_area += M_kickable_margin;
}

void
ServerParam::setBallSize( double value )
{
    M_kickable_area -= M_ball_size;
    M_ball_size = value;
    M_kickable_area += M_ball_size;
}

void
ServerParam::setPlayerSize( double value )
{
    M_control_radius_width += M_player_size;
    M_kickable_area -= M_player_size;
    M_player_size = value;
    M_kickable_area += M_player_size;
    M_control_radius_width -= M_player_size;
}

double
ServerParam::getHalfTimeScaler() const
{
    double value = 1000.0 / ( M_simulator_step / M_slow_down_factor );
    return ( value != 0.0
             ? value
             : EPS );
}

//Have to be careful with integer math, see bug # 800540
void
ServerParam::setHalfTime( int value )
{
    M_raw_half_time = value;
    M_half_time = static_cast< int >( value * getHalfTimeScaler() + 0.5 );
}

int
ServerParam::getRawHalfTime() const
{
    //Have to be careful with integer math, see bug # 800540
    //return static_cast< int >( M_half_time / getHalfTimeScaler() + 0.5 );
    return M_raw_half_time;
}

//Have to be careful with integer math, see bug # 800540
void
ServerParam::setExtraHalfTime( int value )
{
    M_raw_extra_half_time = value < 0 ? 0 : value;
    M_extra_half_time = static_cast< int >( value * getHalfTimeScaler() + 0.5 );
}

int
ServerParam::getRawExtraHalfTime() const
{
    //Have to be careful with integer math, see bug # 800540
    //return static_cast< int >( M_half_time / getHalfTimeScaler() + 0.5 );
    return M_raw_extra_half_time;
}

void
ServerParam::setNrNormalHalfs( int value )
{
    M_nr_normal_halfs = value < 0 ? 0 : value;
}

void
ServerParam::setNrExtraHalfs( int value )
{
    M_nr_extra_halfs = value < 0 ? 0 : value;
}

int
ServerParam::getRawSimStep() const
{
    return M_simulator_step / M_slow_down_factor;
}

int
ServerParam::getRawSenseBodyStep() const
{
    return M_sense_body_step / M_slow_down_factor;
}

int
ServerParam::getRawCoachVisualStep() const
{
    return M_send_vi_step / M_slow_down_factor;
}

int
ServerParam::getRawSendStep() const
{
    return M_send_step / M_slow_down_factor;
}

int
ServerParam::getRawSynchOffset() const
{
    return M_synch_offset / M_slow_down_factor;
}

void
ServerParam::setSynchMode( bool value )
{
    if ( M_synch_mode != value )
    {
        M_synch_mode = value;
        M_lcm_step = lcm( M_simulator_step,
                          lcm( M_send_step,
                               lcm( M_recv_step,
                                    lcm( M_sense_body_step,
                                         lcm( M_send_vi_step,
                                              lcm( std::max( M_synch_see_offset, 1 ),
                                                   ( M_synch_mode ? M_synch_offset : 1 ) ) ) ) ) ) );
    }
}

void
ServerParam::setTeamLeftStart( std::string start )
{
    std::replace( start.begin(), start.end(), '\n', ' ' );
    M_team_l_start =  start;
}

void
ServerParam::setTeamRightStart( std::string start )
{
    std::replace( start.begin(), start.end(), '\n', ' ' );
    M_team_r_start = start;
}

void
ServerParam::setTextLogDir( std::string str )
{
    M_text_log_dir = str;
}

void
ServerParam::setGameLogDir( std::string str )
{
    M_game_log_dir = str;
}

void
ServerParam::setKAwayLogDir( std::string str )
{
    M_keepaway_log_dir = str;
}

void
ServerParam::setCoachMsgFile( std::string str )
{
    M_coach_msg_file = str;
}

void
ServerParam::setFoulDetectProbability( double value )
{
    M_foul_detect_probability = std::max( 0.0, std::min( value, 1.0 ) );
}

void
ServerParam::setRedCardProbability( double value )
{
    M_red_card_probability = std::max( 0.0, std::min( value, 1.0 ) );
}

void
ServerParam::clear()
{
    
}

void
ServerParam::setDefaults()
{
    /* set default parameter */
    M_goal_width = GOAL_WIDTH;

    M_inertia_moment = IMPARAM;
    M_player_size = PLAYER_SIZE;
    M_player_decay = PLAYER_DECAY;
    M_player_rand = PLAYER_RAND;
    M_player_weight = PLAYER_WEIGHT;
    M_player_speed_max = PLAYER_SPEED_MAX;
    M_player_accel_max = PLAYER_ACCEL_MAX ;

    M_stamina_max = STAMINA_MAX;
    M_stamina_inc = STAMINA_INC_MAX;
    M_recover_init = 1.0;
    M_recover_dec_thr = RECOVERY_DEC_THR;
    M_recover_min = RECOVERY_MIN;
    M_recover_dec = RECOVERY_DEC;
    M_effort_init = 1.0;
    M_effort_dec_thr = EFFORT_DEC_THR;
    M_effort_min = EFFORT_MIN;
    M_effort_dec = EFFORT_DEC;
    M_effort_inc_thr = EFFORT_INC_THR;
    M_effort_inc = EFFORT_INC;
    // pfr 8/14/00: for RC2000 evaluation
    M_kick_rand = KICK_RAND;
    M_team_actuator_noise = false;
    M_player_rand_factor_l = PRAND_FACTOR_L;
    M_player_rand_factor_r = PRAND_FACTOR_R;
    M_kick_rand_factor_l = KICK_RAND_FACTOR_L;
    M_kick_rand_factor_r = KICK_RAND_FACTOR_R;

    M_ball_size = BALL_SIZE;
    M_ball_decay = BALL_DECAY;
    M_ball_rand = BALL_RAND;
    M_ball_weight = BALL_WEIGHT;
    M_ball_speed_max = BALL_SPEED_MAX;
    // th 6.3.00
    M_ball_accel_max = BALL_ACCEL_MAX;
    //
    M_dash_power_rate = DASHPOWERRATE;
    M_kick_power_rate = KICKPOWERRATE;
    M_kickable_margin = KICKABLE_MARGIN;
    M_control_radius = CONTROL_RADIUS;

    M_max_power = MAXPOWER;
    M_min_power = MINPOWER;
    M_max_moment = MAXMOMENT;
    M_min_moment = MINMOMENT;
    M_max_neck_moment = MAX_NECK_MOMENT;
    M_min_neck_moment = MIN_NECK_MOMENT;
    M_max_neck_angle = MAX_NECK_ANGLE;
    M_min_neck_angle = MIN_NECK_ANGLE;

    M_visible_angle = VISIBLE_ANGLE;
    M_visible_distance = VISIBLE_DISTANCE;

    M_wind_dir = WIND_DIR;
    M_wind_force = WIND_FORCE;
    M_wind_angle = 0.0;
    M_wind_rand = WIND_RAND;

    M_catchable_area_l = GOALIE_CATCHABLE_AREA_LENGTH;
    M_catchable_area_w = GOALIE_CATCHABLE_AREA_WIDTH;
    M_catch_probability = GOALIE_CATCHABLE_POSSIBILITY;
    M_goalie_max_moves = GOALIE_MAX_MOVES;

    M_keepaway = false;
    M_keepaway_length = KEEPAWAY_LENGTH;
    M_keepaway_width = KEEPAWAY_WIDTH;

    M_corner_kick_margin = CORNER_KICK_MARGIN;
    M_offside_active_area_size = OFFSIDE_ACTIVE_AREA_SIZE;

    M_wind_none = false;
    M_wind_random = false;

    M_port = DEFAULT_PORT_NUMBER;
    M_coach_port = COACH_PORT_NUMBER;
    M_olcoach_port = OLCOACH_PORT_NUMBER;

    M_say_cnt_max = DEF_SAY_COACH_CNT_MAX;
    M_say_coach_msg_size = DEF_SAY_COACH_MSG_SIZE;
    M_clang_win_size = 300;
    M_clang_define_win = 1;
    M_clang_meta_win = 1;
    M_clang_advice_win = 1;
    M_clang_info_win = 1;
    M_clang_mess_delay = 50;
    M_clang_mess_per_cycle = 1;

    M_drop_ball_time = DROP_TIME;
    M_nr_normal_halfs = NR_NORMAL_HALFS;
    M_nr_extra_halfs = NR_EXTRA_HALFS;
    M_penalty_shoot_outs = PENALTY_SHOOT_OUTS;

    M_pen_before_setup_wait = PEN_BEFORE_SETUP_WAIT;
    M_pen_setup_wait        = PEN_SETUP_WAIT;
    M_pen_ready_wait        = PEN_READY_WAIT;
    M_pen_taken_wait        = PEN_TAKEN_WAIT;
    M_pen_nr_kicks          = PEN_NR_KICKS;
    M_pen_max_extra_kicks   = PEN_MAX_EXTRA_KICKS;
    M_pen_dist_x            = PEN_DIST_X;
    M_pen_random_winner     = PEN_RANDOM_WINNER;
    M_pen_allow_mult_kicks  = PEN_ALLOW_MULT_KICKS;
    M_pen_max_goalie_dist_x = PEN_MAX_GOALIE_DIST_X;
    M_pen_coach_moves_players = PEN_COACH_MOVES_PLAYERS;

    M_simulator_step = SIMULATOR_STEP_INTERVAL_MSEC;
    M_sense_body_step = SENSE_BODY_INTERVAL_MSEC;
    M_send_vi_step = SEND_VISUALINFO_INTERVAL_MSEC;
    M_send_step = UDP_SEND_STEP_INTERVAL_MSEC;
    // lcm_st = ...
    M_recv_step = UDP_RECV_STEP_INTERVAL_MSEC;

    M_catch_ban_cycle = GOALIE_CATCH_BAN_CYCLE;
    M_slow_down_factor = 1;

    M_use_offside = true;
    M_forbid_kick_off_offside = true;
    M_offside_kick_margin = OFFSIDE_KICK_MARGIN;

    M_audio_cut_dist = AUDIO_CUT_OFF_DIST;

    M_quantize_step = DIST_QSTEP;
    M_landmark_quantize_step = LAND_QSTEP;

#ifdef NEW_QSTEP
    dir_qstep  = DIR_QSTEP;
    dist_qstep_l = DIST_QSTEP;
    dist_qstep_r = DIST_QSTEP;
    land_qstep_l = LAND_QSTEP;
    land_qstep_r = LAND_QSTEP;
    dir_qstep_l = DIR_QSTEP;
    dir_qstep_r = DIR_QSTEP;
    defined_qstep_l = false;
    defined_qstep_r = false;
    defined_qstep_l_l = false;
    defined_qstep_l_r = false;
    defined_qstep_dir_l = false;
    defined_qstep_dir_r = false;
#endif

    M_verbose = false;

    M_coach_mode = false;
    M_coach_with_referee_mode = false;
    M_old_coach_hear = false;

    M_synch_mode = false;
    M_synch_offset = 60;
    M_synch_micro_sleep = 1;

    M_start_goal_l = 0;
    M_start_goal_r = 0;

    M_fullstate_l = false;
    M_fullstate_r = false;

    M_slowness_on_top_for_left_team = 1.0;
    M_slowness_on_top_for_right_team = 1.0;

    M_landmark_file = LANDMARK_FILE;

    M_send_comms = SEND_COMMS;
    M_text_logging = TEXT_LOGGING;
    M_game_logging = GAME_LOGGING;
    M_game_log_version = GAME_LOG_VERSION;
    M_text_log_dir = TEXT_LOG_DIR;
    M_game_log_dir = GAME_LOG_DIR;
    M_text_log_fixed_name = TEXT_LOG_FIXED_NAME;
    M_game_log_fixed_name = GAME_LOG_FIXED_NAME;
    M_text_log_fixed = TEXT_LOG_FIXED;
    M_game_log_fixed = GAME_LOG_FIXED;
    M_text_log_dated = TEXT_LOG_DATED;
    M_game_log_dated = GAME_LOG_DATED;
    M_log_date_format = LOG_DATE_FORMAT;
    M_log_times = LOG_TIMES;
    M_record_messages = RECORD_MESSAGES;
    M_text_log_compression = TEXT_LOG_COMPRESSION;
    M_game_log_compression = GAME_LOG_COMPRESSION;
    M_profile = PROFILE;

    M_keepaway_logging = KAWAY_LOGGING;
    M_keepaway_log_dir = KAWAY_LOG_DIR;
    M_keepaway_log_fixed_name = KAWAY_LOG_FIXED_NAME;
    M_keepaway_log_fixed = KAWAY_LOG_FIXED;
    M_keepaway_log_dated = KAWAY_LOG_DATED;

    M_keepaway_start = KAWAY_START;

    M_point_to_ban = POINT_TO_BAN;
    M_point_to_duration = POINT_TO_DURATION;

    M_say_msg_size = SAY_MSG_SIZE;
    M_hear_max = HEAR_MAX;
    M_hear_inc = HEAR_INC;
    M_hear_decay = HEAR_DECAY;

    M_tackle_dist = TACKLE_DIST;
    M_tackle_back_dist = TACKLE_BACK_DIST;
    M_tackle_width = TACKLE_WIDTH;
    M_tackle_exponent = TACKLE_EXPONENT;
    M_tackle_cycles = TACKLE_CYCLES;
    M_tackle_power_rate = TACKLE_POWER_RATE;

    M_freeform_wait_period = FREEFORM_WAIT_PERIOD;
    M_freeform_send_period = FREEFORM_SEND_PERIOD;

    M_free_kick_faults = FREE_KICK_FAULTS;
    M_back_passes = BACK_PASSES;

    M_proper_goal_kicks = PROPER_GOAL_KICKS;
    M_stopped_ball_vel = STOPPED_BALL_VEL;
    M_max_goal_kicks = MAX_GOAL_KICKS;

    M_clang_del_win = CLANG_DEL_WIN;
    M_clang_rule_win = CLANG_RULE_WIN;

    M_auto_mode = S_AUTO_MODE;
    M_kick_off_wait = S_KICK_OFF_WAIT;
    M_connect_wait = S_CONNECT_WAIT;
    M_game_over_wait = S_GAME_OVER_WAIT;

    M_team_l_start = S_TEAM_L_START;
    M_team_r_start = S_TEAM_R_START;

    // 11.0.0
    M_ball_stuck_area = BALL_STUCK_AREA;

    M_coach_msg_file = "";

    // 12.0.0
    M_max_tackle_power = MAX_TACKLE_POWER;
    M_max_back_tackle_power = MAX_BACK_TACKLE_POWER;
    M_player_speed_max_min = PLAYER_SPEED_MAX_MIN;
    M_extra_stamina = EXTRA_STAMINA;
    M_synch_see_offset = SYNCH_SEE_OFFSET;

    M_max_monitors = -1;

    // 13.0.0
    M_stamina_capacity = STAMINA_CAPACITY;
    M_max_dash_angle = MAX_DASH_ANGLE;
    M_min_dash_angle = MIN_DASH_ANGLE;
    M_dash_angle_step = DASH_ANGLE_STEP;
    M_side_dash_rate = SIDE_DASH_RATE;
    M_back_dash_rate = BACK_DASH_RATE;
    M_max_dash_power = MAX_DASH_POWER;
    M_min_dash_power = MIN_DASH_POWER;

    // 14.0.0
    M_tackle_rand_factor = TACKLE_RAND_FACTOR;
    M_foul_detect_probability = FOUL_DETECT_PROBABILITY;
    M_foul_exponent = FOUL_EXPONENT;
    M_foul_cycles = FOUL_CYCLES;
    M_random_seed = -1;
    M_golden_goal = GOLDEN_GOAL;

    // 15.0.0
    M_red_card_probability = RED_CARD_PROBABILITY;

    // XXX
    M_long_kick_power_factor = LONG_KICK_POWER_FACTOR;
    M_long_kick_delay = LONG_KICK_DELAY;

    setHalfTime( HALF_TIME );
    setExtraHalfTime( EXTRA_HALF_TIME );
    setSlowDownFactor();

    M_kickable_area = M_player_size + M_kickable_margin + M_ball_size;
    M_control_radius_width = M_control_radius - M_player_size;

//     std::string module_dir = S_MODULE_DIR;
//     for ( std::string::size_type pos = module_dir.find( "//" );
//           pos != std::string::npos;
//           pos = module_dir.find( "//" ) )
//     {
//         module_dir.replace( pos, 2, "/" );
//     }

//     rcss::lib::Loader::setPath( module_dir );
}

server_params_t
ServerParam::convertToStruct() const
{
    server_params_t tmp;

    tmp.gwidth = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_goal_width ) );
    tmp.inertia_moment = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_inertia_moment ) );
    tmp.psize = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_player_size ) );
    tmp.pdecay = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_player_decay ) );
    tmp.prand = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_player_rand ) );
    tmp.pweight = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_player_weight ) );
    tmp.pspeed_max = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_player_speed_max ) );
    tmp.paccel_max = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_player_accel_max ) );
    tmp.stamina_max = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_stamina_max ) );
    tmp.stamina_inc = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_stamina_inc ) );
    tmp.recover_init = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_recover_init ) );
    tmp.recover_dthr = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_recover_dec_thr ) );
    tmp.recover_min = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_recover_min ) );
    tmp.recover_dec = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_recover_dec ) );
    tmp.effort_init = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_effort_init ) );
    tmp.effort_dthr = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_effort_dec_thr ) );
    tmp.effort_min = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_effort_min ) );
    tmp.effort_dec = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_effort_dec ) );
    tmp.effort_ithr = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_effort_inc_thr ) );
    tmp.effort_inc = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_effort_inc ) );
    tmp.kick_rand = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_kick_rand ) );
    tmp.team_actuator_noise = htons( static_cast< Int16 >( M_team_actuator_noise ) );
    tmp.prand_factor_l = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_player_rand_factor_l ) );
    tmp.prand_factor_r = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_player_rand_factor_r ) );
    tmp.kick_rand_factor_l = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_kick_rand_factor_l ) );
    tmp.kick_rand_factor_r = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_kick_rand_factor_r ) );
    tmp.bsize = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_ball_size ) );
    tmp.bdecay = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_ball_decay ) );
    tmp.brand = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_ball_rand ) );
    tmp.bweight = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_ball_weight ) );
    tmp.bspeed_max = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_ball_speed_max ) );
    tmp.baccel_max = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_ball_accel_max ) );
    tmp.dprate = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_dash_power_rate ) );
    tmp.kprate = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_kick_power_rate ) );
    tmp.kmargin = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_kickable_margin ) );
    tmp.ctlradius = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_control_radius ) );
    tmp.ctlradius_width = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_control_radius_width ) );
    tmp.maxp = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_max_power ) );
    tmp.minp = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_min_power ) );
    tmp.maxm = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_max_moment ) );
    tmp.minm = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_min_moment ) );
    tmp.maxnm = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_max_neck_moment ) );
    tmp.minnm = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_min_neck_moment ) );
    tmp.maxn = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_max_neck_angle ) );
    tmp.minn = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_min_neck_angle ) );
    tmp.visangle = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_visible_angle ) );
    tmp.visdist = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_visible_distance ) );
    tmp.windir = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_wind_dir ) );
    tmp.winforce = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_wind_force ) );
    tmp.winang = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_wind_angle ) );
    tmp.winrand = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_wind_rand ) );
    tmp.kickable_area = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_kickable_area ) );
    tmp.catch_area_l = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_catchable_area_l ) );
    tmp.catch_area_w = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_catchable_area_w ) );
    tmp.catch_prob = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_catch_probability ) );
    tmp.goalie_max_moves = htons( static_cast< Int16 >( M_goalie_max_moves ) );
    tmp.ckmargin = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_corner_kick_margin ) );
    tmp.offside_area = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_offside_active_area_size ) );
    tmp.win_no = htons( static_cast< Int16 >( M_wind_none ) );
    tmp.win_random = htons( static_cast< Int16 >( M_wind_random ) );
    tmp.say_cnt_max = htons( static_cast< Int16 >( M_say_cnt_max ) );
    tmp.SayCoachMsgSize = htons( static_cast< Int16 >( M_say_coach_msg_size ) );
    tmp.clang_win_size = htons( static_cast< Int16 >( M_clang_win_size ) );
    tmp.clang_define_win = htons( static_cast< Int16 >( M_clang_define_win ) );
    tmp.clang_meta_win = htons( static_cast< Int16 >( M_clang_meta_win ) );
    tmp.clang_advice_win = htons( static_cast< Int16 >( M_clang_advice_win ) );
    tmp.clang_info_win = htons( static_cast< Int16 >( M_clang_info_win ) );
    tmp.clang_mess_delay = htons( static_cast< Int16 >( M_clang_mess_delay ) );
    tmp.clang_mess_per_cycle = htons( static_cast< Int16 >( M_clang_mess_per_cycle ) );
    tmp.half_time = htons( static_cast< Int16 >( M_raw_half_time ) );
    tmp.sim_st = htons( static_cast< Int16 >( M_simulator_step ) );
    tmp.send_st = htons( static_cast< Int16 >( M_send_step ) );
    tmp.recv_st = htons( static_cast< Int16 >( M_recv_step ) );
    tmp.sb_step = htons( static_cast< Int16 >( M_sense_body_step ) );
    tmp.lcm_st = htons( static_cast< Int16 >( M_lcm_step ) );
    tmp.M_say_msg_size = htons( static_cast< Int16 >( M_say_msg_size ) );
    tmp.M_hear_max = htons( static_cast< Int16 >( M_hear_max ) );
    tmp.M_hear_inc = htons( static_cast< Int16 >( M_hear_inc ) );
    tmp.M_hear_decay = htons( static_cast< Int16 >( M_hear_decay ) );
    tmp.cban_cycle = htons( static_cast< Int16 >( M_catch_ban_cycle ) );
    tmp.slow_down_factor = htons( static_cast< Int16 >( M_slow_down_factor ) );
    tmp.useoffside = htons( static_cast< Int16 >( M_use_offside ) );
    tmp.kickoffoffside = htons( static_cast< Int16 >( M_forbid_kick_off_offside ) );
    tmp.offside_kick_margin = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_offside_kick_margin ) );
    tmp.audio_dist = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_audio_cut_dist ) );
    tmp.dist_qstep = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_quantize_step ) );
    tmp.land_qstep = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_landmark_quantize_step ) );
#ifdef NEW_QSTEP
    tmp.dir_qstep = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * dir_qstep ) );
    tmp.dist_qstep_l = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * dist_qstep_l ) );
    tmp.dist_qstep_r = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * dist_qstep_r ) );
    tmp.land_qstep_l = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * land_qstep_l ) );
    tmp.land_qstep_r = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * land_qstep_r ) );
    tmp.dir_qstep_l = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * dir_qstep_l ) );
    tmp.dir_qstep_r = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * dir_qstep_r ) );
#else
    tmp.dir_qstep = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * -1 ) );
    tmp.dist_qstep_l = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * -1 ) );
    tmp.dist_qstep_r = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * -1 ) );
    tmp.land_qstep_l = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * -1 ) );
    tmp.land_qstep_r = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * -1 ) );
    tmp.dir_qstep_l = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * -1 ) );
    tmp.dir_qstep_r = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * -1 ) );
#endif
    tmp.CoachMode = htons( static_cast< Int16 >( M_coach_mode ) );
    tmp.CwRMode = htons( static_cast< Int16 >( M_coach_with_referee_mode ) );
    tmp.old_hear = htons( static_cast< Int16 >( M_old_coach_hear ) );
    tmp.sv_st = htons( static_cast< Int16 >( M_send_vi_step ) );


    tmp.slowness_on_top_for_left_team = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_slowness_on_top_for_left_team ) );
    tmp.slowness_on_top_for_right_team = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_slowness_on_top_for_left_team ) );

    tmp.ka_length = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_keepaway_length ) );
    tmp.ka_width = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_keepaway_width ) );

    tmp.ball_stuck_area = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_ball_stuck_area ) );

    tmp.max_tackle_power = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_max_tackle_power ) );
    tmp.max_back_tackle_power = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_max_back_tackle_power ) );

    tmp.tackle_dist = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_tackle_dist ) );
    tmp.tackle_back_dist = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_tackle_back_dist ) );
    tmp.tackle_width = htonl( static_cast< Int32 >( SHOWINFO_SCALE2 * M_tackle_width ) );


    tmp.start_goal_l = htons( static_cast< Int16 >( M_start_goal_l ) );
    tmp.start_goal_r = htons( static_cast< Int16 >( M_start_goal_r ) );

    tmp.fullstate_l = htons( static_cast< Int16 >( M_fullstate_l ) );
    tmp.fullstate_r = htons( static_cast< Int16 >( M_fullstate_r ) );

    tmp.drop_time = htons( static_cast< Int16 >( M_drop_ball_time ) );

    tmp.synch_mode   = htons( static_cast< Int16 >( M_synch_mode ) );//pfr:SYNCH
    tmp.synch_offset = htons( static_cast< Int16 >( M_synch_offset ) );//pfr:SYNCH
    tmp.synch_micro_sleep = htons( static_cast< Int16 >( M_synch_micro_sleep ) );//pfr:SYNCH

    tmp.point_to_ban =  htons( static_cast< Int16 >( M_point_to_ban ) );
    tmp.point_to_duration =  htons( static_cast< Int16 >( M_point_to_duration ) );

    return tmp;
}
