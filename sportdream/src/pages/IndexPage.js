import React,{Component} from 'react'
import {
    StyleSheet,
    TouchableHighlight,
    Text,
    View,
    Button,
    Image
} from 'react-native'
import {
    NavigationActions,
    TabBarBottom,
    TabNavigator
} from 'react-navigation'
import {connect} from 'dva'

import {TabBar} from "antd-mobile"
import Tab1Page from './tab/Tab1Page'
import Tab2Page from './tab/Tab2Page'
import Tab3Page from './tab/Tab3Page'
import Tab4Page from './tab/Tab4Page'
import Tab5Page from './tab/Tab5Page'

const IndexNavigator = TabNavigator(
    {
        Tab1:{screen:Tab1Page},
        Tab2:{screen:Tab2Page},
        Tab3:{screen:Tab3Page},
        Tab4:{screen:Tab4Page},
        Tab5:{screen:Tab5Page}
    },
    {
        tabBarComponent: TabBarBottom,
        tabBarPosition: 'bottom',
        swipeEnabled: false,
        animationEnabled: false,
        lazyLoad: true,
    }
)

@connect()
export default class IndexPage extends Component {
    constructor(props) {
        super(props);
        this.state = {
            selectedTab: 'blueTab',
        };
    }

    onChangeTab(tabName) {
        this.setState({
            selectedTab: tabName,
        });
    }

    //
    gotoCount = ()=>{
        this.props.dispatch(NavigationActions.navigate({routeName:'Count'}))
    }

    render() {
        return (
            <TabBar
                unselectedTintColor="#949494"
                tintColor="#33A3F4"
                barTintColor="white"
            >
                <TabBar.Item
                    title="主页"
                    icon={require("../assets/images/tab/篮球场.png")}
                    selectedIcon={require("../assets/images/tab/篮球场_sel.png")}
                    selected={this.state.selectedTab === 'blueTab'}
                    onPress={()=>this.onChangeTab('blueTab')}
                >
                    <Tab1Page navigation={this.props.navigation} />
                </TabBar.Item>
                <TabBar.Item
                    icon={require('../assets/images/tab/group.png')}
                    selectedIcon={require('../assets/images/tab/group_sel.png')}
                    title="关系"
                    badge={2}
                    selected={this.state.selectedTab === 'redTab'}
                    onPress={() => this.onChangeTab('redTab')}
                >
                    <Tab2Page navigation={this.props.navigation} />
                </TabBar.Item>
                <TabBar.Item
                    icon={require('../assets/images/tab/match.png')}
                    selectedIcon={require('../assets/images/tab/match_sel.png')}
                    title="比赛"
                    selected={this.state.selectedTab === 'greenTab'}
                    onPress={() => this.onChangeTab('greenTab')}
                >
                    <Tab3Page navigation={this.props.navigation} />
                </TabBar.Item>
                <TabBar.Item
                    icon={require('../assets/images/tab/shoot.png')}
                    selectedIcon={require('../assets/images/tab/shoot_sel.png')}
                    title="基本功"
                    selected={this.state.selectedTab === 'Tab4'}
                    onPress={() => this.onChangeTab('Tab4')}
                >
                    <Tab4Page navigation={this.props.navigation} />
                </TabBar.Item>
                <TabBar.Item
                    icon={require('../assets/images/tab/my.png')}
                    selectedIcon={require('../assets/images/tab/my_sel.png')}
                    title="我"
                    selected={this.state.selectedTab === 'yellowTab'}
                    onPress={() => this.onChangeTab('yellowTab')}
                >
                    <Tab5Page navigation={this.props.navigation} />
                </TabBar.Item>
            </TabBar>
        )
    }
}
