extends Panel



#export interface INotification {
	#id: string;
	#userId: string;
	#type: NotificationType;
	#title: string;
	#message: string;
	#read: boolean;
	#timestamp: Date;
	#metadata?: NotificationMetadata;
#}
#
#export interface NotificationMetadata {
	#farmName?: string;
	#sensorId?: string;
	#nftId?: string;
	#[key: string]: any;
#}


func slot_data(data: Dictionary) -> void:
	%Message.text = data.message
	%TimeAgo.text = data.timeAgo + " ago"
	
