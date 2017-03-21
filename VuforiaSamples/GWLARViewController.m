//
//  GWLARViewController.m
//  VuforiaSamples
//
//  Created by 龙的LONG on 17/2/21.
//  Copyright © 2017年 Qualcomm. All rights reserved.
//

#import "GWLARViewController.h"

@interface GWLARViewController ()
@property (weak, nonatomic) IBOutlet UILabel *BNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *GWLImage;
@property (weak, nonatomic) IBOutlet UILabel *IDName;
@property (weak, nonatomic) IBOutlet UILabel *JSLabel;

@end

@implementation GWLARViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self.GWLID isEqualToString:@"A00020000925"]) {
        self.BNameLabel.text = @"秋山图";
        self.GWLImage.image = [UIImage imageNamed:@"A00020000925.jpg"];
        self.IDName.text = @"藏品IDA00020000925";
        self.JSLabel.text = @"     《秋山图》正是张大千两项重要事业追求的集中体现：其一，《秋山图》为中国传统画作题材，流传至今的即有五代僧人巨然的《秋山图》和明代画家董其昌的《秋山图》。五代僧巨然《秋山图》是绢本水墨。《秋山图》上有“袁枢明印”、“石愚收藏印信”等收藏印记。亦有“王铎鉴定”，“孟津王镛珍藏”等印，今为台北故宫博物院收藏。明代董其昌《秋山图》，是董其昌于1616年(万历44年丙辰)10月为金玉检所作，是年董其昌62岁";
        
    }else if ([self.GWLID isEqualToString:@"A00020000056"]){
        self.BNameLabel.text = @"诗词歌赋";
        self.GWLImage.image = [UIImage imageNamed:@"A00020000056.jpg"];
        self.IDName.text = @"藏品IDA00020000056";
        self.JSLabel.text = @"     所谓诗词歌赋，是人们对我国传统文学的概称；虽然如此，这一称谓几乎可说是业已概括了中国传统文化的精髓和文化尤其是传统文学的大成。其中，诗词在人们的通常思维中是有着严格格律（主要指平仄、用韵和对偶等严格要求）的两种诗歌体式（古体诗的平仄略微放宽些），是不能乱行押韵和误用平仄的；究其实，所谓的赋，其实也是有着非常严格的对仗规则和平仄要求，只是当今一些习作者因不知而写着罢了。而这，无疑是对传统文化的严重摧残。但这诗词歌赋的创作还是有其自身的独特要求和写作技巧的，人们一旦掌握了，写好它们应该也不是什么太难之事。";
        
    }else if ([self.GWLID isEqualToString:@"A00020000118"]){
        self.BNameLabel.text = @"诗词歌赋";
        self.GWLImage.image = [UIImage imageNamed:@"A00020000118.jpg"];
        self.IDName.text = @"藏品IDA00020000118";
        self.JSLabel.text = @"     所谓诗词歌赋，是人们对我国传统文学的概称；虽然如此，这一称谓几乎可说是业已概括了中国传统文化的精髓和文化尤其是传统文学的大成。其中，诗词在人们的通常思维中是有着严格格律（主要指平仄、用韵和对偶等严格要求）的两种诗歌体式（古体诗的平仄略微放宽些），是不能乱行押韵和误用平仄的；究其实，所谓的赋，其实也是有着非常严格的对仗规则和平仄要求，只是当今一些习作者因不知而写着罢了。而这，无疑是对传统文化的严重摧残。但这诗词歌赋的创作还是有其自身的独特要求和写作技巧的，人们一旦掌握了，写好它们应该也不是什么太难之事。";
        
    }else if ([self.GWLID isEqualToString:@"A00020000147"]){
        self.BNameLabel.text = @"王十朋水仙诗意图";
        self.GWLImage.image = [UIImage imageNamed:@"A00020000147.jpg"];
        self.IDName.text = @"藏品IDA00020000147";
        self.JSLabel.text = @"     题识：叶抽春带秀文房，玉表黄中耐雪霜。得水成仙最风味，与梅为弟各芬香。王十朋咏水仙诗，韩天衡画。钤印：豆庐（朱文）、慎独（朱文）、韩（白文）、天衡（朱文）、百乐斋（朱文）、百乐斋制（白文）)";
        
    }else if ([self.GWLID isEqualToString:@"A00020000278"]){
        self.BNameLabel.text = @"玉印";
        self.GWLImage.image = [UIImage imageNamed:@"A00020000278.jpg"];
        self.IDName.text = @"藏品IDA00020000278";
        self.JSLabel.text = @"     古玺是先秦印章的通称。我们现在所能看到的最早的印章大多是战国古玺。这些古玺的许多文字，现在我们还下认识。朱文古玺大都配上宽边。印文笔画细如毫发，都出于铸造。白文古玺大多加边栏，或在中间加一竖界格，文字有铸有凿。官玺的印文内容有“司马”、“司徒”等名称外，还有各种不规则的形状，内容还刻有吉语和生动的物图案。";
        
    }else if ([self.GWLID isEqualToString:@"A00020000289"]){
        self.BNameLabel.text = @"玉印";
        self.GWLImage.image = [UIImage imageNamed:@"A00020000289.jpg"];
        self.IDName.text = @"藏品IDA00020000289";
        self.JSLabel.text = @"     战国时期，主张合纵的名相苏秦佩戴过六国相印。近几年来，出土的文物又把印章的历史向前推进了数百年。也就是说，印章在周朝时就有了";
        
    }else if ([self.GWLID isEqualToString:@"A00020000310"]){
        self.BNameLabel.text = @"印章";
        self.GWLImage.image = [UIImage imageNamed:@"A00020000310.jpg"];
        self.IDName.text = @"藏品IDA00020000310";
        self.JSLabel.text = @"     中国的雕刻文字，最古的有殷的甲骨文，周的钟鼎文，秦的刻石等，凡在金铜玉石等素材上雕刻的文字通称“金石”。玺印即包括在“金石”里。玺印的起源或说商代，或说殷代，至今尚无定论。根据遗物和历史记载，至少在春秋战国时已出现，战国时代已普遍使用。起初只是作为商业上交流货物时的凭证。秦始皇统一中国后，印章范围扩大为证明当权者权益的法物，为当权者掌握，作为统治人民的工具。";
        
    }else if ([self.GWLID isEqualToString:@"A00020000421"]){
        self.BNameLabel.text = @"对联";
        self.GWLImage.image = [UIImage imageNamed:@"A00020000421.jpg"];
        self.IDName.text = @"藏品IDA00020000421";
        self.JSLabel.text = @"     对联又称楹联、对偶、门对、春贴、春联、对子、桃符等，是一种对偶文学，起源于桃符。对联是利用汉字特征撰写的一种民族文体。一般不需要押韵（律诗中的对联才需要押韵）。对联大致可分诗对联，以及散文对联，严格、分大小词类相对。传统对联的形式相通、内容相连、声调协调、对仗严谨。";
        
    }else if ([self.GWLID isEqualToString:@"A00020000735"]){
        self.BNameLabel.text = @"毛笔";
        self.GWLImage.image = [UIImage imageNamed:@"A00020000735.jpg"];
        self.IDName.text = @"藏品IDA00020000735";
        self.JSLabel.text = @"     毛笔（Chinese brush，writing brush），是一种源于中国的传统书写工具，也逐渐成为传统绘画工具。毛笔是古代中国人民在生产实践中发明的。随着人类社会的不断发展，勤劳智慧的中华民族又不断地总结经验，存其精华，弃其糟粕，勇于探索，敢于创新。几千年以来，它为创造中华民族光辉灿烂的文化，为促进中华民族与世界各族的文化交流，做出了卓越的贡献。毛笔是中华民族对世界艺术宝库提供的一件珍宝。";
        
    }else if ([self.GWLID isEqualToString:@"A00020001085"]){
        self.BNameLabel.text = @"砚台";
        self.GWLImage.image = [UIImage imageNamed:@"A00020001085.jpg"];
        self.IDName.text = @"藏品IDA00020001085";
        self.JSLabel.text = @"     砚台历经秦汉、魏晋，至唐代起，各地相继发现适合制砚的石料，开始以石为主的砚台制作。其中采用广东端州的端石、安徽歙州的歙石及甘肃临洮的洮河石制作的砚台，被分别称作端砚、歙砚、洮河砚。史书将端、歙、临洮砚称作三大名砚。清末，又将山西的澄泥砚与端、歙、临洮，并列为中国四大名砚。也有人主张，以天然砚石雕制的鲁砚中的徐公石砚代替澄泥砚，合称四大名砚";
        
    }else if ([self.GWLID isEqualToString:@"A00020001036"]){
        self.BNameLabel.text = @"石砚";
        self.GWLImage.image = [UIImage imageNamed:@"A00020001036.jpg"];
        self.IDName.text = @"藏品IDA00020001036";
        self.JSLabel.text = @"     汉代刘熙写的《释名》中解释：“砚者研也，可研墨使和濡也”。它是由原始社会的研磨器演变而来。初期的砚，形态原始，是用一块小研石在一面磨平的石器上压墨丸研磨成墨汁。至汉时，砚上出现了雕刻，有石盖，下带足。魏晋至隋出现了圆形瓷砚，由三足而多足。箕形砚是唐代常见的砚式，形同簸箕，砚底一端落地，一端以足支撑。唐、宋时，砚台的造型更加多样化。";
        
    }else if ([self.GWLID isEqualToString:@"A00020001041"]){
        self.BNameLabel.text = @"砚台盖";
        self.GWLImage.image = [UIImage imageNamed:@"A00020001041.jpg"];
        self.IDName.text = @"藏品IDA00020001041";
        self.JSLabel.text = @"     砚台历经秦汉、魏晋，至唐代起，各地相继发现适合制砚的石料，开始以石为主的砚台制作。其中采用广东端州的端石、安徽歙州的歙石及甘肃临洮的洮河石制作的砚台，被分别称作端砚、歙砚、洮河砚。史书将端、歙、临洮砚称作三大名砚。清末，又将山西的澄泥砚与端、歙、临洮，并列为中国四大名砚。也有人主张，以天然砚石雕制的鲁砚中的徐公石砚代替澄泥砚，合称四大名砚";
        
    }}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)GWLbackButton:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
- (IBAction)SCButton:(UIButton *)sender {
}
- (IBAction)NOButton:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

/**
 不知道他搞得咋样了
 
 ********/







/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
